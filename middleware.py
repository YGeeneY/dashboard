import asyncio

import aiohttp_jinja2
from aiohttp import web
from aiohttp_session import get_session


@asyncio.coroutine
def error_middleware(app, handler):
    def middleware_handler(request):
        response_404 = aiohttp_jinja2.render_template('404.html', request, {})
        session = yield from get_session(request)
        try:
            response = yield from handler(request)
            if response.status == 404:
                return response_404
            if request.path == '/':
                return response
            if session.get('user') is None:
                return web.HTTPFound('/')
            return response
        except web.HTTPException as ex:
            if ex.status == 404:
                return response_404
            raise
    return middleware_handler
