package notifications

import (
	"fmt"
	"log"
	"net/smtp"
	"os"

	"github.com/andresnsn/agendamento-app/backend/internal/models"
)

type Notifier struct {
	adminEmail string
	adminPhone string
	smtpHost   string
	smtpPort   string
	smtpUser   string
	smtpPass   string
}

func NewNotifier() *Notifier {
	return &Notifier{
		adminEmail: os.Getenv("ADMIN_EMAIL"),
		adminPhone: os.Getenv("ADMIN_PHONE"),
		smtpHost:   getEnv("SMTP_HOST", "smtp.gmail.com"),
		smtpPort:   getEnv("SMTP_PORT", "587"),
		smtpUser:   os.Getenv("SMTP_USER"),
		smtpPass:   os.Getenv("SMTP_PASS"),
	}
}

func (n *Notifier) NotifyNewAppointment(appointment models.Appointment) {
	log.Printf(
		"[NOTIFICATION] Novo agendamento: %s agendou para %s às %s",
		appointment.UserName, appointment.Date, appointment.TimeSlot,
	)

	if n.adminEmail != "" && n.smtpUser != "" {
		go n.sendEmail(appointment)
	}

	// SMS notification via Twilio would go here
	if n.adminPhone != "" {
		log.Printf("[SMS] Notificação para %s: Novo agendamento de %s",
			n.adminPhone, appointment.UserName)
	}
}

func (n *Notifier) sendEmail(appointment models.Appointment) {
	subject := "Novo Agendamento"
	body := fmt.Sprintf(
		"Novo agendamento recebido!\n\nCliente: %s\nData: %s\nHorário: %s\n",
		appointment.UserName, appointment.Date, appointment.TimeSlot,
	)

	msg := fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		n.smtpUser, n.adminEmail, subject, body,
	)

	auth := smtp.PlainAuth("", n.smtpUser, n.smtpPass, n.smtpHost)
	addr := fmt.Sprintf("%s:%s", n.smtpHost, n.smtpPort)

	if err := smtp.SendMail(addr, auth, n.smtpUser, []string{n.adminEmail}, []byte(msg)); err != nil {
		log.Printf("[EMAIL ERROR] Failed to send email: %v", err)
	} else {
		log.Printf("[EMAIL] Notificação enviada para %s", n.adminEmail)
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
