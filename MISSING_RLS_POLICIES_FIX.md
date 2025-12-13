# Missing RLS Policies Fix - Issue #57

## Problem Description
The `tickets` and `ticket_comments` tables were missing critical DELETE and UPDATE RLS policies, which prevented legitimate users from performing necessary operations.

### Issues Identified:
1. **tickets table**: Missing DELETE policy
2. **ticket_comments table**: Missing UPDATE policy
3. **ticket_comments table**: Missing DELETE policy

Without these policies, users could not:
- Delete tickets they created or were assigned to
- Update their own comments
- Delete their own comments
- Admins could not manage tickets/comments in their team

## Changes Made

### File Modified:
- `sqls/04_tickets_schema.sql`

### 1. Added DELETE Policy for Tickets

**Policy Name**: `tickets_delete_policy`

**Allows deletion by**:
- Ticket creator (`created_by`)
- Assigned user (`assigned_to`)
- Team admins

```sql
CREATE POLICY tickets_delete_policy ON tickets
    FOR DELETE
    USING (
        auth.uid() = created_by OR 
        auth.uid() = assigned_to OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.team_id = tickets.team_id 
            AND users.role = 'admin'
        )
    );
```

**Rationale**:
- **Creator**: Should be able to delete tickets they created
- **Assigned user**: Has ownership and should be able to close/delete
- **Team admins**: Need full control over team resources

### 2. Added UPDATE Policy for Ticket Comments

**Policy Name**: `ticket_comments_update_policy`

**Allows updates by**:
- Comment owner (`user_id`)
- Team admins

```sql
CREATE POLICY ticket_comments_update_policy ON ticket_comments
    FOR UPDATE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM tickets 
            JOIN users ON users.team_id = tickets.team_id
            WHERE tickets.id = ticket_comments.ticket_id 
            AND users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );
```

**Rationale**:
- **Comment owner**: Should be able to edit their own comments (fix typos, clarify)
- **Team admins**: Need ability to moderate comments if necessary

### 3. Added DELETE Policy for Ticket Comments

**Policy Name**: `ticket_comments_delete_policy`

**Allows deletion by**:
- Comment owner (`user_id`)
- Team admins

```sql
CREATE POLICY ticket_comments_delete_policy ON ticket_comments
    FOR DELETE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM tickets 
            JOIN users ON users.team_id = tickets.team_id
            WHERE tickets.id = ticket_comments.ticket_id 
            AND users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );
```

**Rationale**:
- **Comment owner**: Should be able to delete their own comments
- **Team admins**: Need moderation capabilities

## Complete RLS Policy Summary for Tickets

### Tickets Table Policies:
| Operation | Policy Name | Who Can Access |
|-----------|-------------|----------------|
| SELECT | `tickets_view_policy` | All team members |
| INSERT | `tickets_insert_policy` | Any team member (as creator) |
| UPDATE | `tickets_update_policy` | Creator, Assigned user, Team admins |
| DELETE | `tickets_delete_policy` | Creator, Assigned user, Team admins ✅ NEW |

### Ticket Comments Table Policies:
| Operation | Policy Name | Who Can Access |
|-----------|-------------|----------------|
| SELECT | `ticket_comments_view_policy` | All team members |
| INSERT | `ticket_comments_insert_policy` | Any team member |
| UPDATE | `ticket_comments_update_policy` | Comment owner, Team admins ✅ NEW |
| DELETE | `ticket_comments_delete_policy` | Comment owner, Team admins ✅ NEW |

## Security Considerations

### Access Control Matrix:

#### Tickets:
- ✅ **Regular Users**: Can view, create, update (own), delete (own)
- ✅ **Assigned Users**: Can view, create, update, delete
- ✅ **Team Admins**: Full control (view, create, update, delete all team tickets)
- ❌ **Other Teams**: No access (enforced by team_id check)

#### Ticket Comments:
- ✅ **Comment Owner**: Can view, create, update (own), delete (own)
- ✅ **Team Admins**: Can view, create, update (all), delete (all)
- ✅ **Team Members**: Can view, create comments
- ❌ **Other Teams**: No access (enforced by ticket team_id check)

## Benefits of This Fix

1. **Complete Access Control**: All CRUD operations now have proper RLS policies
2. **User Empowerment**: Users can manage their own content appropriately
3. **Admin Control**: Admins have necessary moderation capabilities
4. **Team Isolation**: Cross-team access is still properly prevented
5. **Consistency**: Policies follow the same pattern as other tables

## Testing Recommendations

After applying these changes, test the following scenarios:

### Tickets DELETE Tests:
1. ✅ Creator should be able to delete their ticket
2. ✅ Assigned user should be able to delete their assigned ticket
3. ✅ Team admin should be able to delete any team ticket
4. ❌ Non-creator/non-assigned user should NOT be able to delete
5. ❌ User from another team should NOT be able to delete

### Ticket Comments UPDATE Tests:
1. ✅ Comment owner should be able to update their comment
2. ✅ Team admin should be able to update any team comment
3. ❌ Other users should NOT be able to update someone else's comment
4. ❌ User from another team should NOT be able to update

### Ticket Comments DELETE Tests:
1. ✅ Comment owner should be able to delete their comment
2. ✅ Team admin should be able to delete any team comment
3. ❌ Other users should NOT be able to delete someone else's comment
4. ❌ User from another team should NOT be able to delete

## Migration Steps

If applying to an existing database:

1. **Backup your database first**
2. Connect to your database
3. Run the updated `04_tickets_schema.sql` file, or manually add policies:

```sql
-- Add DELETE policy for tickets
CREATE POLICY tickets_delete_policy ON tickets
    FOR DELETE
    USING (
        auth.uid() = created_by OR 
        auth.uid() = assigned_to OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.team_id = tickets.team_id 
            AND users.role = 'admin'
        )
    );

-- Add UPDATE policy for ticket_comments
CREATE POLICY ticket_comments_update_policy ON ticket_comments
    FOR UPDATE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM tickets 
            JOIN users ON users.team_id = tickets.team_id
            WHERE tickets.id = ticket_comments.ticket_id 
            AND users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Add DELETE policy for ticket_comments
CREATE POLICY ticket_comments_delete_policy ON ticket_comments
    FOR DELETE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM tickets 
            JOIN users ON users.team_id = tickets.team_id
            WHERE tickets.id = ticket_comments.ticket_id 
            AND users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );
```

4. Verify policies are created:
```sql
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('tickets', 'ticket_comments')
ORDER BY tablename, cmd;
```

Expected output should show:
- 4 policies for `tickets` (SELECT, INSERT, UPDATE, DELETE)
- 4 policies for `ticket_comments` (SELECT, INSERT, UPDATE, DELETE)

## Conclusion

This fix completes the RLS policy coverage for tickets and ticket_comments tables, ensuring that:
- ✅ All CRUD operations are properly secured
- ✅ Users have appropriate permissions for their content
- ✅ Admins have necessary control over team resources
- ✅ Cross-team data isolation is maintained
- ✅ The system follows security best practices

Closes #57
