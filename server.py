import jinja2
import aiohttp_jinja2
from aiohttp import web
import logging
from aiohttp_session import setup
from aiohttp_session.cookie_storage import EncryptedCookieStorage

from interval_handlers import run_with_interval
from middleware import error_middleware
from routes import routes
from settings import TEMPLATE_DIR, SECRET_KEY
from jinja2_filters import nl2br

handler = logging.StreamHandler()
logger = logging.getLogger()
logger.addHandler(handler)
logger.setLevel(logging.DEBUG)


app = web.Application()
setup(app, EncryptedCookieStorage(SECRET_KEY))
app.middlewares.append(error_middleware)
aiohttp_jinja2.setup(app, loader=jinja2.FileSystemLoader(TEMPLATE_DIR))
env = aiohttp_jinja2.get_env(app)
env.filters['nl2br'] = nl2br


for route in routes:
    app.router.add_route(**route)

app.loop.create_task(run_with_interval())
web.run_app(app)
