package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/andresnsn/agendamento-app/backend/internal/auth"
	"github.com/andresnsn/agendamento-app/backend/internal/models"
	"github.com/andresnsn/agendamento-app/backend/internal/notifications"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

type AppointmentHandler struct {
	db       *sql.DB
	notifier *notifications.Notifier
}

func NewAppointmentHandler(db *sql.DB, notifier *notifications.Notifier) *AppointmentHandler {
	return &AppointmentHandler{db: db, notifier: notifier}
}

func (h *AppointmentHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims := auth.GetUserClaims(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "Não autorizado")
		return
	}

	var req models.CreateAppointmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	var slotAvailable bool
	var slotTime string
	err := h.db.QueryRow(
		"SELECT is_available, time FROM time_slots WHERE id = $1 AND date = $2",
		req.TimeSlotID, req.Date,
	).Scan(&slotAvailable, &slotTime)

	if err == sql.ErrNoRows {
		writeError(w, http.StatusNotFound, "Horário não encontrado")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}
	if !slotAvailable {
		writeError(w, http.StatusConflict, "Horário não está disponível")
		return
	}

	id := uuid.New().String()
	_, err = h.db.Exec(
		"INSERT INTO appointments (id, user_id, slot_id, status) VALUES ($1, $2, $3, 'confirmed')",
		id, claims.UserID, req.TimeSlotID,
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao criar agendamento")
		return
	}

	h.db.Exec("UPDATE time_slots SET is_available = FALSE WHERE id = $1", req.TimeSlotID)

	var userName string
	h.db.QueryRow("SELECT name FROM users WHERE id = $1", claims.UserID).Scan(&userName)

	appointment := models.Appointment{
		ID:       id,
		UserID:   claims.UserID,
		UserName: userName,
		Date:     req.Date,
		TimeSlot: slotTime,
		SlotID:   req.TimeSlotID,
		Status:   "confirmed",
	}

	go h.notifier.NotifyNewAppointment(appointment)

	writeJSON(w, http.StatusCreated, appointment)
}

func (h *AppointmentHandler) GetMyAppointments(w http.ResponseWriter, r *http.Request) {
	claims := auth.GetUserClaims(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "Não autorizado")
		return
	}

	rows, err := h.db.Query(`
		SELECT a.id, a.user_id, u.name, ts.date, ts.time, a.slot_id, a.status, a.created_at
		FROM appointments a
		JOIN users u ON a.user_id = u.id
		JOIN time_slots ts ON a.slot_id = ts.id
		WHERE a.user_id = $1
		ORDER BY ts.date DESC, ts.time DESC
	`, claims.UserID)
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

func (h *AppointmentHandler) Cancel(w http.ResponseWriter, r *http.Request) {
	claims := auth.GetUserClaims(r)
	if claims == nil {
		writeError(w, http.StatusUnauthorized, "Não autorizado")
		return
	}

	id := mux.Vars(r)["id"]

	var slotID string
	err := h.db.QueryRow(
		"SELECT slot_id FROM appointments WHERE id = $1 AND user_id = $2",
		id, claims.UserID,
	).Scan(&slotID)
	if err == sql.ErrNoRows {
		writeError(w, http.StatusNotFound, "Agendamento não encontrado")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}

	h.db.Exec("UPDATE appointments SET status = 'cancelled' WHERE id = $1", id)
	h.db.Exec("UPDATE time_slots SET is_available = TRUE WHERE id = $1", slotID)

	writeJSON(w, http.StatusOK, map[string]string{"message": "Agendamento cancelado"})
}
