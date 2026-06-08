import asyncio
import websockets
import json
from app.database import SessionLocal
from app.models.user import User
from app.utils.security import create_access_token

async def test_conn():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "admin@demo.com").first()
        if not user:
            print("Admin user not found in database!")
            return
        
        token = create_access_token({
            "sub": user.email,
            "role": user.role.value,
            "entity_id": user.id,
            "tenant_id": user.tenant_id,
        })
        print(f"Generated token for {user.email} (role={user.role.value})")
    finally:
        db.close()

    uri = f"ws://localhost:8000/ws/{token}"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected successfully!")
            
            # Wait for welcome message
            welcome = await websocket.recv()
            print("Received welcome message:", json.loads(welcome))

            # Send ping
            await websocket.send(json.dumps({"type": "ping"}))
            print("Sent ping")
            
            # Receive pong
            pong = await websocket.recv()
            print("Received pong:", json.loads(pong))
            
    except Exception as e:
        print("Connection failed:", e)

if __name__ == "__main__":
    asyncio.run(test_conn())
