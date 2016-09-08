from helpers import route
from handlers import *
from api_handlers import *


routes = (
    # HTML routes
    route('*',    '/', index, name='index'),
    route('GET',  '/vip', vips, name='vips'),

    route('GET',  '/issues', issues, name='issues'),
    route('GET',  '/issues/{client:\w{1,32}}', single_client_issues, name='single_client_issues'),
    route('*',    '/issue/{issue_id:\d+}', single_issue, name='single_issue'),
    route('POST', '/issue', create_issue, name='create_issue'),

    # API routes
    route('GET',  '/api/clients', clients_api, name='api_client'),
    route('GET',  '/api/history', history_api, name='api_get_history'),
)
