package main

import (
	"log"
	"net/http"
	"os"

	"github.com/andresnsn/agendamento-app/backend/internal/auth"
	"github.com/andresnsn/agendamento-app/backend/internal/database"
	"github.com/andresnsn/agendamento-app/backend/internal/handlers"
	"github.com/andresnsn/agendamento-app/backend/internal/notifications"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

func main() {
	db, err := database.Connect()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	notifier := notifications.NewNotifier()
	authHandler := handlers.NewAuthHandler(db)
	slotHandler := handlers.NewSlotHandler(db)
	appointmentHandler := handlers.NewAppointmentHandler(db, notifier)
	adminHandler := handlers.NewAdminHandler(db, notifier)

	r := mux.NewRouter()

	// Health check
	r.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	}).Methods("GET")

	// Public routes
	api := r.PathPrefix("/api").Subrouter()
	api.HandleFunc("/auth/login", authHandler.Login).Methods("POST")
	api.HandleFunc("/auth/register", authHandler.Register).Methods("POST")
	api.HandleFunc("/auth/social", authHandler.SocialLogin).Methods("POST")

	// Protected routes
	protected := api.PathPrefix("").Subrouter()
	protected.Use(auth.AuthMiddleware)

	protected.HandleFunc("/slots", slotHandler.GetSlots).Methods("GET")
	protected.HandleFunc("/appointments", appointmentHandler.Create).Methods("POST")
	protected.HandleFunc("/appointments/me", appointmentHandler.GetMyAppointments).Methods("GET")
	protected.HandleFunc("/appointments/{id}", appointmentHandler.Cancel).Methods("DELETE")

	// Admin routes
	admin := api.PathPrefix("/admin").Subrouter()
	admin.Use(auth.AuthMiddleware)
	admin.Use(auth.AdminMiddleware)

	admin.HandleFunc("/appointments", adminHandler.GetAllAppointments).Methods("GET")
	admin.HandleFunc("/appointments", adminHandler.CreateAppointment).Methods("POST")
	admin.HandleFunc("/appointments/{id}", adminHandler.DeleteAppointment).Methods("DELETE")
	admin.HandleFunc("/slots", adminHandler.CreateSlot).Methods("POST")
	admin.HandleFunc("/slots/{id}", adminHandler.DeleteSlot).Methods("DELETE")
	admin.HandleFunc("/users", adminHandler.GetUsers).Methods("GET")

	// CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		AllowCredentials: true,
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	handler := c.Handler(r)

	log.Printf("Server starting on port %s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
