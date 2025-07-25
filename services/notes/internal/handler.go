package internal

import (
	notespb "github.com/izstoev10/ai_assistant/services/notes"
)

type NotesServer struct {
	notespb.UnimplementedNotesServer
}

func NewNotesServer() *NotesServer {
	return &NotesServer{}
}
