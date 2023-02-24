# WMK server backend
#
# Kotov E.
# v0.1
#
# python 3

from typing import Any

import socketserver
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import requests
import cgi
import io
import datetime
from urllib import parse

# WML Modules
import check_user_access
import users_actions
#import logger
#
# https://pymotw.com/3/http.server/  - very good example

def log_add(errstr, PRINT_ERRORS='NO'):
    try:
        with open("logs/server.http.log", "a") as logfile:
            logfile.write('\n' + str(datetime.datetime.now()) + "\t" + str(errstr))
            if (PRINT_ERRORS == 'YES'):
                print(str(datetime.datetime.now()) + "\t" + str(errstr))
        logfile.close()
    except Exception as e:
        print("# Error. Func log_add: " + str(e))
    return 0



class Server(BaseHTTPRequestHandler):

    # Log actions
    # def log_add(self, errstr, PRINT_ERRORS='NO'):
    #     with open("logs/server.http.log", "a") as logfile:
    #         logfile.write('\n' + str(datetime.datetime.now()) + "\t" + str(errstr))
    #         if (PRINT_ERRORS == 'YES'):
    #             print(str(datetime.datetime.now()) + "\t" + str(errstr))
    #     logfile.close()
    #     return 0

    def log_http(self):
        parsed_path = parse.urlparse(self.path)
        # message_parts = [
        #     'CLIENT VALUES:',
        #     ' client_address={} ({})'.format(
        #         self.client_address,
        #         self.address_string()),
        #     ' command={}'.format(self.command),
        #     ' path={}'.format(self.path),
        #     ' real path={}'.format(parsed_path.path),
        #     ' query={}'.format(parsed_path.query),
        #     ' request_version={}'.format(self.request_version),
        #     '',
        #     'SERVER VALUES:',
        #     ' server_version={}'.format(self.server_version),
        #     ' sys_version={}'.format(self.sys_version),
        #     ' protocol_version={}'.format(self.protocol_version),
        #     '',
        #     'HEADERS RECEIVED:',
        # ]
        message_parts = ' IP: ' + str(self.client_address) +\
            '. Command: ' + str(self.command) +\
            '. Query: ' + str(parsed_path.query)

        for name, value in sorted(self.headers.items()):
            message_parts = message_parts +\
                '. %s=%s' % (name, value.rstrip())

        log_add('Log. Connected client. Method GET/POST.' + message_parts)
    ##############



    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_HEAD(self):
        self._set_headers()

    # GET sends back a Hello world message
    def do_GET(self):
        # Get client data
        self.log_http()
        self._set_headers()
        self.wfile.write(json.dumps({'hello': 'world', 'received': 'ok'}).encode('utf-8'))


    def POST_JSON(self):
        length = int(self.headers['content-length'])
        # Get and check JSON format
        try:
            message = json.loads(self.rfile.read(length)) #dictionary type
        except ValueError as e:
            log_add('ERROR. Func POST_JSON. Data is not  in JSON  format. '+  '. Error text: ' + str(e) + 'Request lenght: ' + str(length),'YES' )
            self._set_headers()
            self.wfile.write(json.dumps('{"action": "", "error":"Main json parsing" , "data":{"message" : "Data is not  in JSON  format."}}').encode('utf-8'))
            return False

        log_add('LOG. Func POST_JSON. Get data: ' + str(message))
        # Get user action
        result, result_text = users_actions.on_GET_JSON(message)

        log_add(result_text,'NO')
        #Send result
        self._set_headers()
        self.wfile.write(json.dumps(result).encode('utf-8'))
        return True


    def POST_other(self):
        # Parse the form data posted
        form = cgi.FieldStorage(
            fp=self.rfile,
            headers=self.headers, 
            environ={
                'REQUEST_METHOD': 'POST',
                'CONTENT_TYPE': self.headers['Content-Type'],
            }
        )

        # Begin the response
        self.send_response(200)
        self.send_header('Content-Type',
                         'text/plain; charset=utf-8')
        self.end_headers()

        out = io.TextIOWrapper(
            self.wfile,
            encoding='utf-8',
            line_buffering=False,
            write_through=True,
        )

        out.write('Client: {}\n'.format(self.client_address))
        out.write('User-agent: {}\n'.format(
            self.headers['user-agent']))
        out.write('Path: {}\n'.format(self.path))
        out.write('Form data:\n')

        # Echo back information about what was posted in the form
        for field in form.keys():
            field_item = form[field]
            if field_item.filename:
                # The field contains an uploaded file
                file_data = field_item.file.read()
                file_len = len(file_data)
                del file_data
                msg = '\tUploaded {} as {!r} ({} bytes)\n'.format(field, field_item.filename, file_len)
            else:
                # Regular form value
                msg = '\t{}={}\n'.format( field, form[field].value )
            out.write(msg)
            log_add('LOG. Get POST_other data: '+ str(msg))

        # Disconnect our encoding wrapper from the underlying
        # buffer so that deleting the wrapper doesn't close
        # the socket, which is still being used by the server.
        out.detach()


    # POST echoes the message adding a JSON field
    def do_POST(self):
        self.log_http()
        ctype, spid = cgi.parse_header(self.headers['content-type'])
        # refuse to receive non-json content
        if ctype == 'application/json':
            # curl --data "{\"this\":\"is a test\"}" --header "Content-Type: application/json" http://localhost:8009
            self.POST_JSON()
        elif ctype == 'multipart/form-data':
            # curl -v http://localhost:8009 -F name=dhellmann -F foo=bar -F datafile=@http_server_GET.py
            self.POST_other()
        else:
            self.send_error(404)
        return


def run(server_class=HTTPServer, handler_class=Server, port=8099):
    server_address = ('', port)    
    try:
        httpd = HTTPServer(server_address, handler_class)
        sa = httpd.socket.getsockname()        
        log_add("Start serving HTTP on " + str(sa[0]) + " port " + str(sa[1]) + "...", 'YES')
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    log_add("Stop serving HTTP ...", 'YES')



if __name__ == "__main__":
    from sys import argv
    print(argv)
    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
