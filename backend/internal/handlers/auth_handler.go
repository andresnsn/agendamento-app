package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/andresnsn/agendamento-app/backend/internal/auth"
	"github.com/andresnsn/agendamento-app/backend/internal/models"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db *sql.DB
}

func NewAuthHandler(db *sql.DB) *AuthHandler {
	return &AuthHandler{db: db}
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	var user models.User
	err := h.db.QueryRow(
		"SELECT id, name, email, phone, password_hash, is_admin, auth_provider FROM users WHERE email = $1",
		req.Email,
	).Scan(&user.ID, &user.Name, &user.Email, &user.Phone, &user.PasswordHash, &user.IsAdmin, &user.AuthProvider)

	if err == sql.ErrNoRows {
		writeError(w, http.StatusUnauthorized, "E-mail ou senha inválidos")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		writeError(w, http.StatusUnauthorized, "E-mail ou senha inválidos")
		return
	}

	token, err := auth.GenerateToken(user.ID, user.Email, user.IsAdmin)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao gerar token")
		return
	}

	writeJSON(w, http.StatusOK, models.AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	if req.Name == "" || req.Email == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "Nome, e-mail e senha são obrigatórios")
		return
	}

	if len(req.Password) < 6 {
		writeError(w, http.StatusBadRequest, "Senha deve ter no mínimo 6 caracteres")
		return
	}

	var exists bool
	h.db.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", req.Email).Scan(&exists)
	if exists {
		writeError(w, http.StatusConflict, "E-mail já cadastrado")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro interno")
		return
	}

	id := uuid.New().String()
	_, err = h.db.Exec(
		"INSERT INTO users (id, name, email, phone, password_hash) VALUES ($1, $2, $3, $4, $5)",
		id, req.Name, req.Email, req.Phone, string(hash),
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao criar usuário")
		return
	}

	user := models.User{
		ID:    id,
		Name:  req.Name,
		Email: req.Email,
		Phone: req.Phone,
	}

	token, err := auth.GenerateToken(user.ID, user.Email, user.IsAdmin)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao gerar token")
		return
	}

	writeJSON(w, http.StatusCreated, models.AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) SocialLogin(w http.ResponseWriter, r *http.Request) {
	var req models.SocialLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Dados inválidos")
		return
	}

	// TODO: Validate token with Firebase Auth
	writeError(w, http.StatusNotImplemented, "Login social será implementado com Firebase Auth")
}
