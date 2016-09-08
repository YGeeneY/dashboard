import os

BASE_DIR = os.path.dirname(os.path.realpath(__file__))
TEMPLATE_DIR = os.path.join(BASE_DIR, 'templates')
SQL_DIR = os.path.join(BASE_DIR, 'sql')


QUERY = dict(INSTANCE_QUERY_GF=os.path.join(SQL_DIR, 'get_vip_from_main.sql'),
             INSTANCE_QUERY_LOCAL=os.path.join(SQL_DIR, 'get_vip_local.sql'),
             ISSUES_QUERY=os.path.join(SQL_DIR, 'issues.sql'),
             SINGLE_CLIENT_ISSUES_QUERY=os.path.join(SQL_DIR, 'single_client_issues.sql'),
             ISSUES_COUNT=os.path.join(SQL_DIR, 'issues_count.sql'),
             SINGLE_ISSUE=os.path.join(SQL_DIR, 'single_issue.sql'),
             COMMENTS=os.path.join(SQL_DIR, 'comments.sql'),
             )
SECRET_KEY = b'YHuMvIRhCVdtEGNrZwDnofSbTzKPBlji'
RENEW_CLIENTS = True

DB_GF = dict(
    database='',
    user='',
    password='',
    host='')

DB_LOCAL = dict(
    database='',
    user='',
    password='',
    host='')
