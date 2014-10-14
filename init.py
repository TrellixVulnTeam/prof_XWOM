import requests
import urllib

baseurl = "https://prof.fil.univ-lille1.fr"
prof_session = requests.Session()


def initiate_session(login, password):
    prof_session.get(baseurl+"/index.php")
    payload = {
        'login': login,
        'passwd': urllib.parse.quote_plus(password),
        '++O+K++': 'Valider'
    }
    work_html = prof_session.post(baseurl+"/login.php", params=payload)

    return work_html
