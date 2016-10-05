import sys, os, bottle

sys.path = ['/opt/rsyslogweb/'] + sys.path
os.chdir(os.path.dirname(__file__))

###import todo # This loads your application
import rsyslogweb

application = bottle.default_app()


