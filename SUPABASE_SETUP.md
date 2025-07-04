# Supabase Setup Guide for Ell-ena Team ID System

This guide explains how to set up Supabase for the Ell-ena application's Team ID system.

## 1. Create a Supabase Project

1. Go to [Supabase](https://supabase.com/) and sign in or create an account
2. Create a new project with your preferred name and database password
3. Wait for the project to be created (this may take a few minutes)

## 2. Set Up Database Schema

1. In your Supabase project dashboard, navigate to the SQL Editor
2. Create a new query and paste the contents of the `supabase_schema.sql` file
3. Run the query to create all necessary tables, policies, and functions

## 3. Configure Authentication

1. In your Supabase project, go to Authentication → Settings
2. Under Email Auth, make sure "Enable Email Signup" is turned on
3. Customize the email templates if needed

## 4. Set Up Environment Variables

1. Copy your Supabase URL and anon key from the project settings
2. Update the `.env` file in your Flutter project with these values:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 5. Test the Setup

1. Run the Flutter application
2. Try creating a new team and verify that:
   - A 6-character team ID is generated
   - The team ID is displayed in a dialog with a copy button
   - The team is created in the Supabase database
3. Try joining an existing team and verify that:
   - The team ID is validated
   - Users can only join if the team ID exists
   - Users are properly associated with the team in the database

## Database Schema

### Teams Table
- `id`: UUID (primary key)
- `name`: Text (team name)
- `team_code`: Text (6-character unique team ID)
- `created_at`: Timestamp
- `created_by`: UUID (user who created the team)

### Users Table
- `id`: UUID (primary key, linked to auth.users)
- `full_name`: Text
- `email`: Text (unique)
- `team_id`: UUID (foreign key to teams.id)
- `role`: Text ('admin' or 'member')
- `created_at`: Timestamp
- `updated_at`: Timestamp

## Row Level Security (RLS)

The database uses Row Level Security to ensure that:
- Users can only view their own team's data
- Only team admins can update team information
- Users can update their own profiles

## Team ID Generation

Team IDs are 6-character alphanumeric codes (e.g., A06OUI, X7K9L2) that are:
- Automatically generated when creating a new team
- Validated when joining an existing team
- Unique across all teams 