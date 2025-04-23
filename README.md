# Ell-ena

## 🤝 AI-Powered Context-Aware Task Automation System
Ell-ena is an intelligent productivity assistant that transforms natural language commands into structured tasks, tickets, and meeting summaries using ModernBERT for NLP and Graph RAG for contextual memory. Designed for developers, students, and project managers, it eliminates app-switching by providing a unified interface for task management.

## Cloud Architecture Diagram of the Ellena

![image](https://github.com/user-attachments/assets/3c699321-4d09-40fc-9872-a1199f834c28)

## Flow Chart Diagram of the Ellena

![image](https://github.com/user-attachments/assets/fa1d539d-d0bb-498e-9456-449d51c77be1)


If you want a closer look at the architecture, check the [Architecture file](https://app.eraser.io/workspace/k2JTVQhjbGO9yhCbnKwd?origin=share) 



## **Features**  

✅ **Natural Language Processing**
- Converts voice/text commands like "Create ticket for dark mode by Friday" into structured tasks using ModernBERT
- Handles complex dependencies through contextual understanding

✅ **Graph RAG Integration**
- Maintains relationships between tasks/projects using Neo4j graph database
- Enables smart recommendations (e.g., suggests related backend tickets when adding OAuth login)

✅ **Meeting Intelligence**
- Auto-generates transcripts with speaker diarization
- Extracts action items using AI summary engine

✅ **Cross-Platform Dashboard**
- Real-time task tracking (To-Do/In Progress/Completed)
- Productivity analytics with completion trends
- Unified view for tickets, meetings, and deadlines

✅ **Context-Aware Automation**
- Remembers project-specific terminology and workflows
- Auto-fills task details using historical context



## 🎨 Figma Designs

To ensure an intuitive and seamless user experience, I have designed the entire workflow of Ell-ena in Figma. The designs incorporate all the proposed and required features to provide a smooth interaction for both doctors and patients. These prototypes serve as a blueprint for development, and I will do my best to translate them into fully functional and efficient code.

If you want to take a closer look at the designs, check out this [Figma Design](https://www.figma.com/design/xhnMPzO8hrqXllGdEOCLZj/Ell-ena?node-id=0-1&t=07fZ8BhKPk4QLyw0-1).

### User Flow

![image](https://github.com/user-attachments/assets/028110ee-47cf-4cc2-b25b-8d03eb68d221)


## Tech Stack

### Frontend
Flutter for building a cross-platform application (iOS/Android). 
### Backend: 
Appwrite for authentication, database management, and real-time 
updates. 
###  AI Models 
Integration of natural language processing models for command parsing and context understanding using ModernBERT for intent recognition and GPT-4 for generative responses  
### Graph Database
Neo4j for implementing Graph RAG to model relationships between tasks, projects, and users

## **🔄 Workflow**  

### User Workflows
Task Creation Flow
User speaks/writes command
ModernBERT extracts:
Intent (create_task)
Entities (feature="dark mode", deadline=Friday)
Graph RAG retrieves related:
Project documentation
Existing tickets
System generates structured task with auto-filled:

json
`
{
  "title": "Implement Dark Mode",  
  "project": "UI Overhaul",  
  "dependencies": ["COLOR-32", "AUTH-15"],  
  "context": "Linked to 3 meeting discussions"  
}`



## Project Structure

```
lib/
├── core/
│   ├── models/
│   ├── theme/
│   └── widgets/
├── presentation/
│   ├── auth/
│   ├── dashboard/
│   └── splash_screen.dart
└── providers/
```

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## UI Design

The app features a modern and clean UI design with:

- Custom animations
- Gradient colors
- Responsive layouts
- Consistent color scheme
- Modern input fields and buttons

## Next Steps

- Backend integration
- API services
- Local data persistence
- Push notifications 
