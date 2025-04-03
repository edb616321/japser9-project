# N8N Chat Workflow Configuration Backup

## Webhook Configuration
- Production URL: https://n8n.brookmanfamily.com/webhook/c2320118-7f7c-4a79-9947-75fd024ebeb8
- Method: POST
- Authentication: None
- Response: Immediately
- Response Code: 200
- CORS: Enabled (*)

## Workflow Structure
1. Webhook Node
   - Receives POST requests with actions: sendMessage, loadPreviousSession

2. Switch Node
   - Routes based on action:
     - Output 0: loadPreviousSession → PostgreSQL Query
     - Output 1: sendMessage → AI Agent

3. PostgreSQL Node (for loadPreviousSession)
   - Query:
   ```sql
   SELECT json_build_object(
     'messages', json_agg(
       json_build_object(
         'content', message->>'content',
         'role', message->>'role'
       ) ORDER BY id ASC
     )
   ) as chat_history
   FROM public.n8n_chat_histories 
   WHERE session_id = '{{ $json.body.sessionId }}';
   ```

4. AI Agent Configuration
   - Model: Ollama Chat Model
   - Memory: PostgreSQL Chat Memory

## Test Commands
```bash
# Test sendMessage
curl -X POST https://n8n.brookmanfamily.com/webhook/c2320118-7f7c-4a79-9947-75fd024ebeb8 \
-H "Content-Type: application/json" \
-d '{"action": "sendMessage", "chatInput": "Hello, how are you?", "sessionId": "test123"}' -k

# Test loadPreviousSession
curl -X POST https://n8n.brookmanfamily.com/webhook/c2320118-7f7c-4a79-9947-75fd024ebeb8 \
-H "Content-Type: application/json" \
-d '{"action": "loadPreviousSession", "sessionId": "test123"}' -k
```
