package handlers

import (
	"database/sql"
	"net/http"

	"github.com/andresnsn/agendamento-app/backend/internal/models"
)

type SlotHandler struct {
	db *sql.DB
}

func NewSlotHandler(db *sql.DB) *SlotHandler {
	return &SlotHandler{db: db}
}

func (h *SlotHandler) GetSlots(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date == "" {
		writeError(w, http.StatusBadRequest, "Parâmetro 'date' é obrigatório")
		return
	}

	rows, err := h.db.Query(
		"SELECT id, date, time, is_available FROM time_slots WHERE date = $1 ORDER BY time",
		date,
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao buscar horários")
		return
	}
	defer rows.Close()

	slots := []models.TimeSlot{}
	for rows.Next() {
		var slot models.TimeSlot
		if err := rows.Scan(&slot.ID, &slot.Date, &slot.Time, &slot.IsAvailable); err != nil {
			continue
		}
		slots = append(slots, slot)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"slots": slots})
}
