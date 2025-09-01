   # Google Summer of Code 2025 - Final Report


   - **Project:** [Ell-ena: AI-Powered Task Manager](https://github.com/AOSSIE-Org/Ell-ena)
   - **Organization:** [Australian Open Source Software Innovation and Education (AOSSIE)](https://www.aossie.org/) 
   - **Name:** Garv Agarwal  
   - **GitHub:** [SharkyBytes](https://github.com/SharkyBytes)  
   - **Social Profiles:** [LinkedIn](https://www.linkedin.com/in/garv-agarwal-99759b251/)   
   - **Mentor(s):** jddeep, Bhavik Mangla, Pranavi Tadivalasa, Bruno

   --- 

   ## Project Description

Managing tasks, meetings, and team collaboration can quickly become overwhelming with traditional tools. Switching between apps, manually updating tasks, and missing key discussion points slows down productivity and creates confusion.

Ell-ena addresses these challenges by combining chat, voice, and quick command inputs into a single cross-platform task manager. It syncs tasks and meetings in real time, while an AI-powered bot captures important meeting discussions and shares actionable insights with the team. With AI-driven automation, speech recognition, and multiple visualization modes like calendars and Kanban boards, Ell-ena ensures work flows naturally- helping teams stay organized, aligned, and productive without getting bogged down by the tools themselves.

   ---

   ##  Goals of the Project

   - **Scalable AI-powered task management pipeline** Build a distributed system leveraging LLMs and speech-to-text models to enable natural language, voice, and chat-based task, ticket, and meeting management.
   - **Real-time collaboration & automation**  Integrate contextual meeting transcription, automated summarization, and intelligent linking of tasks, deadlines, and tickets.
   - **Context-aware decision-making (RAG)** Use of Retrieval-Augmented Generation (RAG) to recall and retrieve past discussions, tasks, and meeting data for context-aware decisions.
   - **Cross-platform accessibility** Develop an intuitive **Flutter** app with **Supabase + PostgreSQL** backend, ensuring secure, role-based, and real-time data management.
   ---


   ## Technologies Used

   - **Frontend**: Flutter (Dart), Riverpod, Voice/Audio package, SharedPreferences, NDK  
   - **Backend & Infra**: Supabase (Auth, DB, Storage, Realtime, RPCs, Edge Functions), PostgreSQL (RLS, SQL Triggers)  
   - **AI & Processing**: Function-calling pipelines, Speech-to-Text Transcriber, Embeddings + RAG for contextual retrieval, VEXA Transcriber Engine Workflow
   - **Integrations**: URL Launcher, GitHub Actions (CI/CD)  
   - **Collaboration & Docs**: Markdown, Enhanced README, GitHub Workflow  
--- 


## Proposed Figma Design and Architecture

[Figma Workspace](https://www.figma.com/design/xhnMPzO8hrqXllGdEOCLZj/Ell-ena?node-id=0-1&t=9M88wLskO0K0tdnT-1)


---


## Work Summary

During GSoC 2025, I developed **Ell-ena**, an AI-powered productivity assistant designed to automate task management and enhance team collaboration. Ell-ena provides a **chat-based, natural language interface**, allowing users to create tasks, tickets, and meeting notes simply by typing or speaking commands such as:

- *“Create a ticket to work on the dark mode feature.”*  
- *“Add a to-do list item for my math assignment.”*  

The system interprets user intent, enriches tasks with contextual information, and stores them in a **PostgreSQL backend** with caching for high-frequency lookups. A **pub/sub channel** delivers cross-device updates with sub-second latency, ensuring real-time collaboration.

I built a **cross-platform Flutter app** with responsive dashboards, supporting mobile platforms. The app features a **calendar view** for scheduling, a **Kanban board** with drag-and-drop state transitions, and **optimistic UI updates** for minimal latency. It integrates **Supabase Auth** with OTP verification, secure role-based access, and **Row-Level Security (RLS)** for backend protection.

On the AI side, I implemented **function-calling pipelines** and **Graph RAG workflows** to enable contextual task linking, automated summarization, and retrieval-augmented generation (RAG) for decision-making. Users can schedule meetings by providing a link, and Ell-ena automatically creates the event, updates Kanban and calendar boards in real-time, and notifies all relevant team members.

The **Ell-ena Transcriber Bot** joins the meeting shortly before it starts, captures multi-speaker audio in real-time using **VEXA**, processes it with **Whisper + VAD**, and generates live transcriptions with minimal hallucination. Scheduled pipelines with **Gemini AI** automatically summarize key decisions, action items, and deadlines, linking them directly to tasks.  

This workflow ensures meeting management, reduces manual follow-ups, and provides the entire team with full context in a single click.

I optimized system performance by managing session handling, caching, listener disposal, and multi-team switching while ensuring infrastructure stability. Additionally, I developed end-to-end documentation, including setup guides, architectural overviews, and AI-generated summaries to facilitate onboarding and future contributions.

The result is a **scalable, AI-driven assistant** that reduces manual work, improves coordination, and empowers teams to focus on meaningful outcomes rather than administrative overhead.

---

## Demos

- [Quick Overview of Ell-ena](https://drive.google.com/file/d/1ZsfqbfQ1VWEDu6Dnxkd_J85pqJYDTKuW/view?usp=sharing)  
- [Ell-ena Bot Transcriber in Action](https://drive.google.com/file/d/1n_QrTqLhSamjVUbLOsV8_tO5K2Xb-Hj7/view?usp=sharing)  
- [Context-Aware RAG Functionality in Ell-ena](https://drive.google.com/file/d/1MRpfPKD5-fXMY3eaQs6t-xkqtc69iqNc/view?usp=sharing)  
- [Ell-ena Mid-Evaluation Progress Demo: Sign-Up, Profile, and Kanban Board Flows](https://drive.google.com/file/d/16aQF7FtQWFIEAa_B_7cTNcC0S2V2gX_h/view?usp=sharing)  

---

   ## Learnings

   - **Advanced AI Integration** – Gained hands-on experience building AI features like natural language scheduling, context-aware task management, and meeting transcription. Learned to design RAG pipelines, manage embeddings with Supabase Edge Functions, and orchestrate AI workflows across multiple features.

   - **Development at Scale** – Strengthened skills in development, managing authentication, role-based access, and complex workflows. Focused on performance, state management, and reliable session handling.

   - **Practical Systems Design** – Learned the value of modular architecture, clear data flows, and maintainable code. Gained experience with SQL triggers, row-level security, and backend automation to keep data consistent.

   - **AI-Driven Productivity Tools** – Explored challenges of context-aware AI, from automated summarization to action item extraction. Developed a solid understanding of retrieval-augmented generation, prompt engineering, and applying AI to real user workflows.

   - **Open-Source & Collaboration Skills** – Improved communication with mentors and contributors, managed PRs and issues, wrote clear documentation, and maintained clean commit histories.

   - **Professional Growth & Problem-Solving** – Enhanced skills in debugging complex features, optimizing performance, and handling deployment challenges.

   - **Mindset & Vision** – Realized that impactful AI products require attention to usability and context, not just coding. Developed a long-term perspective on creating tools that genuinely help teams work smarter.

   ---

   ## Challenges Faced

During the development of Ell-ena, I encountered several technical and workflow challenges that helped me grow as a developer:

- **AI Context Management** – Ensuring accurate context retrieval in meetings and tasks was complex. Designing the RAG pipeline to efficiently recall past discussions and link related tasks required careful planning and testing.  

- **Cross-Platform Consistency** – Building a Flutter app addressing UI responsiveness, platform-specific behavior, and state management across devices.  

- **Real-Time Collaboration** – Implementing live updates for tasks, tickets, and meetings using Supabase’s real-time features involved handling concurrency, race conditions, and session synchronization.  

- **Meeting Transcription & Summarization** – Real-time multi-speaker transcription, automated summarization, and linking decisions/action items to tasks demanded precise integration of speech-to-text pipelines and AI summarization models.  

- **Backend Security & Data Integrity** – Implementing RLS Policies, SQL triggers, and role-based access control to ensure proper permissions and maintain consistent data was challenging...especially when integrating AI workflows.  

- **Performance Optimization** – Optimizing state management, listener disposal, session handling required iterative profiling and adjustments.  

- **Collaboration & Documentation** – Coordinating PRs, managing issues, and keeping documentation up-to-date while actively developing features demanded disciplined workflow management and communication.  

These challenges provided valuable learning experiences and helped me a lot to develop practical skills for building scalable, AI-dirven Ell-ena.

---
   ## Contributions

   ### Pull Requests  

   - [#27](https://github.com/AOSSIE-Org/Ell-ena/pull/27) [DOCS]: Added comprehensive setup instructions and Ell-ena summary to documentation  

   - [#26](https://github.com/AOSSIE-Org/Ell-ena/pull/26) [FIX]: Refactored Chat Screen and Schemas — Added listener disposal, state cleanup, and resolved code issues  
   - [#25](https://github.com/AOSSIE-Org/Ell-ena/pull/25) [FEAT]: Implemented RAG-based AI Meeting Context retrieval workflow using Supabase Edge Functions + RPCs and embedding-001  
   - [#24](https://github.com/AOSSIE-Org/Ell-ena/pull/24) [FIX]: Voice Chat Widget in EllenaChatScreen & UserProfile Improvements  
   - [#23](https://github.com/AOSSIE-Org/Ell-ena/pull/23) [FEAT]: Team switching, transcription & summary in DeviceStorage, dashboard metrics update, and Cron-based summarization  
   - [#22](https://github.com/AOSSIE-Org/Ell-ena/pull/22) [FEAT]: Automated Meeting Transcription Summarization via Supabase Edge Functions  
   - [#21](https://github.com/AOSSIE-Org/Ell-ena/pull/21) [FEAT]: Dynamic Dashboard Metrics, Enhanced Profile Insights, and Ellena Voice Chat Integration  
   - [#19](https://github.com/AOSSIE-Org/Ell-ena/pull/19) [FEAT]: Natural Language Scheduling, Meeting Transcription via EllenaTranscriber, and Automated SQL Cleanup Triggers  
   - [#16](https://github.com/AOSSIE-Org/Ell-ena/pull/16) [FEAT]: Integrated Gemini-Powered Smart Chat with Intent Recognition and Function Calling for Automated Task, Ticket, and Meeting Management  
   - [#14](https://github.com/AOSSIE-Org/Ell-ena/pull/14) [FEAT]: Implemented calendar overview with dynamic task/tickets/meeting creation, profile improvements, and performance optimisations  
   - [#12](https://github.com/AOSSIE-Org/Ell-ena/pull/12) [FEAT]: Added meeting scheduling service with URL launcher, admin controls, and build optimisations  
   - [#11](https://github.com/AOSSIE-Org/Ell-ena/pull/11) [FEAT]: Added ticket management system with approval and assignee flow, drag-drop board, and comments  
   - [#10](https://github.com/AOSSIE-Org/Ell-ena/pull/10) [FEAT]: Added full task creation flow with approval, drag-drop statuses, and comments  
   - [#9](https://github.com/AOSSIE-Org/Ell-ena/pull/9) [AUTH]: Integrated Supabase OTP flows with secure admin-team management and SQL refactors  
   - [#4](https://github.com/AOSSIE-Org/Ell-ena/pull/4) [DOCS]: Added issue and PR templates to improve repository structure  
   - [#3](https://github.com/AOSSIE-Org/Ell-ena/pull/3) [FEAT]: Implemented initial Ell-ena structure with design-aligned setup  

   ### Key Issues Resolved


   - [#20](https://github.com/AOSSIE-Org/Ell-ena/issues/20) [FEATURE REQUEST]: Replacing static dashboard and profile metrics, and enable Voice Chat in Ellena chatScreen  

   - [#18](https://github.com/AOSSIE-Org/Ell-ena/issues/18) [DOCS UPDATE]: Supabase SQL Deployment & Edge Functions Setup  
   - [#17](https://github.com/AOSSIE-Org/Ell-ena/issues/17) [FEATURE REQUEST]: Implement Automated Meeting Bot Service with Live Transcription and AI Summary  
   - [#15](https://github.com/AOSSIE-Org/Ell-ena/issues/15) [FEATURE]: Integrate Smart Chat Service with Intent Recognition for Tasks, Tickets, and Meetings  
   - [#13](https://github.com/AOSSIE-Org/Ell-ena/issues/13) [FEATURE]: Implement Advanced Calendar Screen with Dynamic Task, Tickets and Meeting Integration  
   - [#8](https://github.com/AOSSIE-Org/Ell-ena/issues/8) [FEATURE]: Implement meeting creation with purpose, invites, and AI transcription options  
   - [#7](https://github.com/AOSSIE-Org/Ell-ena/issues/7) [FEATURE]: Develop ticket management system with admin approvals, priorities, and progress tracking  
   - [#6](https://github.com/AOSSIE-Org/Ell-ena/issues/6) [FEATURE]: Implement task management flow with admin approvals and role-based operations  
   - [#5](https://github.com/AOSSIE-Org/Ell-ena/issues/5) [AUTH]: Architect team-based authentication and role management with Supabase integration  
   - [#2](https://github.com/AOSSIE-Org/Ell-ena/issues/2) [ENHANCEMENT]: Add Issue Templates for Better Contribution Structure  
   - [#1](https://github.com/AOSSIE-Org/Ell-ena/issues/1) [SETUP]: Initialize project structure for Ell-ena based on proposal designs

--- 

##  Resources & References

- [Project Repo](https://github.com/AOSSIE-Org/Ell-ena)  
- [Documentation](https://github.com/AOSSIE-Org/Perspective?tab=readme-ov-file#table-of-contents)  
- [Supabase Documentation](https://supabase.com/docs/reference/dart/introduction)  
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Packages](https://pub.dev/)

---


## Future Work / Next Steps

Ell-ena has built a strong foundation as an AI-powered task management system, but there’s still room to make it even more helpful, intuitive, and efficient for teams:

- **Improved Meeting Intelligence** – Make real-time meeting transcriptions and summaries better with smarter models, support for multiple languages, and simple sentiment and priority checks to easily spot the important points.

- **Better Team Collaboration** – Add features like threaded conversations and @mentions to keep discussions organized.  

- **Tool Integration** – Integrate with popular platforms like Google Workspace and Google Calendar with Ell-ena’s calendar up to date, and connect mailing services so mentions and important updates show up directly in the associated mail.

- **Offline Support & Improvements** – Allow users to create and edit tasks offline, with automatic syncing when back online. Further optimize caching, database queries, and workflow pipelines to handle larger teams smoothly.  

- **Personalization & Customization** – Let users tweak AI behavior, notification preferences, and board layouts to match their unique workflow and make Ell-ena feel truly personal.  

- **Smarter AI Assistance** – Make the AI assistant smarter so it can understand what users really mean, give useful context-based suggestions, and proactively recommend tasks. Adding support for images and documents will help it provide deeper insights during task and meeting management.

These enhancements aim to make Ell-ena smarter, more collaborative, and more seamless—helping teams stay aligned and productive without extra effort.

---
*I’m deeply grateful to my mentors - Jaideep Prasad, Bhavik Mangla, Pranavi Tadivalasa and Bruno Woltzenlogel Paleo at AOSSIE - for their guidance, feedback, and constant support throughout my GSoC journey. This report, along with the code, demo video, and links above, marks the grand finale of my Google Summer of Code 2025. Cheers!🎉*

