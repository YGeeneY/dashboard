import asyncio
from urllib.parse import parse_qs
from hashlib import md5

import aiohttp_jinja2
from aiohttp import web
from aiohttp_session import get_session

from helpers import local_db_wrapper, Issue, Comment, Instance
from settings import QUERY

__all__ = [
    'vips',
    'issues',
    'single_client_issues',
    'single_issue',
    'index',
    'create_issue'
]


@asyncio.coroutine
def create_issue(request):
    post_data = yield from request.read()
    post_data = parse_qs(post_data.decode())
    client = post_data.get('client')
    body = post_data.get('body')
    if client and body:
        query = "SELECT * FROM create_task(%s, %s)"
        yield from local_db_wrapper(query, parameters=(client[0], body[0]))
    return web.HTTPFound('/issues')


@aiohttp_jinja2.template('vip.html')
@asyncio.coroutine
def vips(request):
    with open(QUERY['INSTANCE_QUERY_LOCAL'], 'r') as get_vips_query:
        fetch = yield from local_db_wrapper(get_vips_query.read())
        instances = [Instance(*row) for row in fetch]
    return {'vips': instances}


@aiohttp_jinja2.template('issues.html')
@asyncio.coroutine
def issues(request):
    with open(QUERY['ISSUES_QUERY'], 'r') as query:
        fetch = yield from local_db_wrapper(query.read())
        issues_list = [Issue(*row) for row in fetch]
        return {'issues': issues_list}


@aiohttp_jinja2.template('client_issues.html')
@asyncio.coroutine
def single_client_issues(request):
    client = request.match_info['client']
    with open(QUERY['SINGLE_CLIENT_ISSUES_QUERY'], 'r') as query:
        fetch = yield from local_db_wrapper(query.read(), parameters=(client,))
        issues_list = [Issue(*row) for row in fetch]
        return {'issues': issues_list, 'client': client}


@aiohttp_jinja2.template('issue.html')
@asyncio.coroutine
def single_issue(request):
    issue_id = request.match_info['issue_id']
    session = yield from get_session(request)
    user = session.get('user')
    if request.method == 'GET':
        with open(QUERY['SINGLE_ISSUE']) as single_issue_query, open(QUERY['COMMENTS']) as comments_query:
            issue_args = yield from local_db_wrapper(single_issue_query.read(), parameters=(issue_id,))
            if not issue_args:
                return web.HTTPNotFound
            issue = Issue(*issue_args[0])
            comments_args = yield from local_db_wrapper(comments_query.read(), parameters=(issue_id,))
            comments = [Comment(*row) for row in comments_args]
            return {'issue': issue, 'comments': comments, 'client': issue.username}
    elif request.method == 'POST':
        post_data = yield from request.read()
        post_data = parse_qs(post_data.decode())
        comment = post_data.get('comment')

        if comment and issue_id:
            yield from local_db_wrapper('SELECT * FROM create_comment(%s, %s, %s)',
                                        parameters=(issue_id, comment[0], user))
        return web.HTTPFound('/issue/{}'.format(issue_id,))


@aiohttp_jinja2.template('index.html')
@asyncio.coroutine
def index(request):
    session = yield from get_session(request)
    if request.method == 'GET':
        if session.get('user') is not None:
            return web.HTTPFound('/vip')
        return dict()
    else:
        post_data = yield from request.read()
        post_data = parse_qs(post_data.decode())
        pwd = post_data.get('pwd')
        if pwd:
            query = 'SELECT type FROM accounts WHERE password = %s'
            pwd = md5(pwd[0].encode()).hexdigest()
            account = yield from local_db_wrapper(query, parameters=(pwd,))
            if not account:
                return web.HTTPForbidden
            session['user'] = account[0][0]
            return web.HTTPFound('/vip')
