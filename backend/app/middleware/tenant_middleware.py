"""
Middleware Multi-tenant.
Extrae el tenant_id del JWT y lo inyecta en request.state para cada petición.
"""
from fastapi import Request, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from app.utils.security import decode_token

oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


async def tenant_middleware(request: Request, call_next):
    """
    Middleware que extrae tenant_id del JWT y lo coloca en request.state.
    Las rutas públicas (health, login, register, docs) no requieren tenant.
    """
    # Rutas que no requieren tenant
    public_paths = ["/", "/docs", "/redoc", "/openapi.json", "/api/health",
                    "/api/auth/login", "/api/auth/register", "/api/tenants"]

    path = request.url.path
    if any(path.startswith(p) for p in public_paths) or path.startswith("/uploads"):
        request.state.tenant_id = None
        response = await call_next(request)
        return response

    # Extraer token del header Authorization
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ")[1]
        try:
            payload = decode_token(token)
            request.state.tenant_id = payload.get("tenant_id")
        except Exception:
            request.state.tenant_id = None
    else:
        request.state.tenant_id = None

    response = await call_next(request)
    return response


def get_tenant_id(request: Request) -> int:
    """Dependency para obtener el tenant_id del request.state."""
    tenant_id = getattr(request.state, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(status_code=403, detail="Tenant no identificado")
    return tenant_id
