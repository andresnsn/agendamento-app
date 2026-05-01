package models

import "time"

type User struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Email        string    `json:"email"`
	Phone        *string   `json:"phone,omitempty"`
	PasswordHash string    `json:"-"`
	IsAdmin      bool      `json:"is_admin"`
	AuthProvider *string   `json:"auth_provider,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type TimeSlot struct {
	ID          string    `json:"id"`
	Date        string    `json:"date"`
	Time        string    `json:"time"`
	IsAvailable bool      `json:"is_available"`
	CreatedAt   time.Time `json:"created_at"`
}

type Appointment struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	UserName  string    `json:"user_name"`
	Date      string    `json:"date"`
	TimeSlot  string    `json:"time_slot"`
	SlotID    string    `json:"slot_id"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type RegisterRequest struct {
	Name     string  `json:"name"`
	Email    string  `json:"email"`
	Password string  `json:"password"`
	Phone    *string `json:"phone,omitempty"`
}

type SocialLoginRequest struct {
	Provider string `json:"provider"`
	Token    string `json:"token"`
}

type CreateAppointmentRequest struct {
	Date       string `json:"date"`
	TimeSlotID string `json:"time_slot_id"`
}

type AdminCreateAppointmentRequest struct {
	UserID     string `json:"user_id"`
	Date       string `json:"date"`
	TimeSlotID string `json:"time_slot_id"`
}

type CreateSlotRequest struct {
	Date string `json:"date"`
	Time string `json:"time"`
}

type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}
