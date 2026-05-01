package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/andresnsn/agendamento-app/backend/internal/models"
	"github.com/andresnsn/agendamento-app/backend/internal/notifications"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

type AdminHandler struct {
	db       *sql.DB
	notifier *notifications.Notifier
}

func NewAdminHandler(db *sql.DB, notifier *notifications.Notifier) *AdminHandler {
	return &AdminHandler{db: db, notifier: notifier}
}

func (h *AdminHandler) GetAllAppointments(w http.ResponseWriter, r *http.Request) {
	dateFilter := r.URL.Query().Get("date")
	statusFilter := r.URL.Query().Get("status")

	query := `
		SELECT a.id, a.user_id, u.name, ts.date, ts.time, a.slot_id, a.status, a.created_at
		FROM appointments a
		JOIN users u ON a.user_id = u.id
		JOIN time_slots ts ON a.slot_id = ts.id
		WHERE 1=1
	`
	args := []interface{}{}
	argIdx := 1

	if dateFilter != "" {
		query += fmt.Sprintf(" AND ts.date = $%d", argIdx)
		args = append(args, dateFilter)
		argIdx++
	}
	if statusFilter != "" {
		query += fmt.Sprintf(" AND a.status = $%d", argIdx)
		args = append(args, statusFilter)
	}

	query += " ORDER BY ts.date DESC, ts.time DESC"

	rows, err := h.db.Query(query, args...)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao buscar agendamentos")
		return
	}
	defer rows.Close()

	appointments := []models.Appointment{}
	for rows.Next() {
		var a models.Appointment
		if err := rows.Scan(&a.ID, &a.UserID, &a.UserName, &a.Date, &a.TimeSlot, &a.SlotID, &a.Status, &a.CreatedAt); err != nil {
			continue
		}
		appointments = append(appointments, a)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"appointments": appointments})
}

func (h *AdminHandler) DeleteAppointment(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]

	var slotID string
	err := h.db.QueryRow("SELECT slot_id FROM appointments WHERE id = $1", id).Scan(&slotID)
	if err == sql.ErrNoRows {
		writeError(w, http.StatusNotFound, "Agendamento não encontrado")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}

	h.db.Exec("DELETE FROM appointments WHERE id = $1", id)
	h.db.Exec("UPDATE time_slots SET is_available = TRUE WHERE id = $1", slotID)

	writeJSON(w, http.StatusOK, map[string]string{"message": "Agendamento excluído"})
}

func (h *AdminHandler) CreateAppointment(w http.ResponseWriter, r *http.Request) {
	var req models.AdminCreateAppointmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	var slotTime string
	err := h.db.QueryRow(
		"SELECT time FROM time_slots WHERE id = $1 AND date = $2 AND is_available = TRUE",
		req.TimeSlotID, req.Date,
	).Scan(&slotTime)
	if err == sql.ErrNoRows {
		writeError(w, http.StatusNotFound, "Horário não encontrado ou indisponível")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}

	id := uuid.New().String()
	_, err = h.db.Exec(
		"INSERT INTO appointments (id, user_id, slot_id, status) VALUES ($1, $2, $3, 'confirmed')",
		id, req.UserID, req.TimeSlotID,
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao criar agendamento")
		return
	}

	h.db.Exec("UPDATE time_slots SET is_available = FALSE WHERE id = $1", req.TimeSlotID)

	var userName string
	h.db.QueryRow("SELECT name FROM users WHERE id = $1", req.UserID).Scan(&userName)

	appointment := models.Appointment{
		ID:       id,
		UserID:   req.UserID,
		UserName: userName,
		Date:     req.Date,
		TimeSlot: slotTime,
		SlotID:   req.TimeSlotID,
		Status:   "confirmed",
	}

	writeJSON(w, http.StatusCreated, appointment)
}

func (h *AdminHandler) CreateSlot(w http.ResponseWriter, r *http.Request) {
	var req models.CreateSlotRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	if req.Date == "" || req.Time == "" {
		writeError(w, http.StatusBadRequest, "Data e horário são obrigatórios")
		return
	}

	id := uuid.New().String()
	_, err := h.db.Exec(
		"INSERT INTO time_slots (id, date, time) VALUES ($1, $2, $3)",
		id, req.Date, req.Time,
	)
	if err != nil {
		writeError(w, http.StatusConflict, "Horário já existe para esta data")
		return
	}

	slot := models.TimeSlot{
		ID:          id,
		Date:        req.Date,
		Time:        req.Time,
		IsAvailable: true,
	}

	writeJSON(w, http.StatusCreated, slot)
}

func (h *AdminHandler) DeleteSlot(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]

	result, err := h.db.Exec("DELETE FROM time_slots WHERE id = $1", id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao excluir horário")
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		writeError(w, http.StatusNotFound, "Horário não encontrado")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "Horário excluído"})
}

func (h *AdminHandler) GetUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(
		"SELECT id, name, email, phone, is_admin, auth_provider FROM users ORDER BY name",
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao buscar usuários")
		return
	}
	defer rows.Close()

	users := []models.User{}
	for rows.Next() {
		var u models.User
		if err := rows.Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.IsAdmin, &u.AuthProvider); err != nil {
			continue
		}
		users = append(users, u)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"users": users})
}
