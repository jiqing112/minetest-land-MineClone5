from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import pprint
import time
import glob
import os

hostName = "localhost"
serverPort = 8080

paths = {}

def dump(obj):
	s = ''
	for attr in dir(obj):
		s = s + "obj.%s = %r" % (attr, getattr(obj, attr)) + "\n"
	return s

def get_png(path):
	if path in paths:
		return Path(pahts[path]).read_bytes()
	for file in glob.glob("../**/" + path, recursive = True):
		paths[path] = file
		return Path(file).read_bytes()
	return

def scan():
	for file in glob.glob("../**/*.png", recursive = True):
		basename = os.path.basename(file)
		if basename in paths:
			print("Duplicate texture name, please fix:\n * %s:\n    - %s\n    - %s\n" % (basename, paths[basename], file))
		else:
			paths[basename] = file

def color_picker():
	return """
		<canvas id="myCanvas" width="256" height="256"></canvas>
		<br/>
		<input type='text' size=7 id='color'/>
		<script>
			function componentToHex(c) {
				var hex = c.toString(16);
				return hex.length == 1 ? "0" + hex : hex;
			}
			function function_down(v, d){
				if (d<=1) {
					return Math.min(255, Math.floor((1-v) * d * 255))
				}
				return 255-Math.min(255, Math.floor(v * (2-d) * 255))
			}
			function function_up(v, d){
				if (d<=1) {
					return Math.min(255, Math.floor(v * d * 255))
				}
				return 255-Math.min(255, Math.floor((1-v) * (2-d) * 255))
			}
			function function_keep(v, d){
				return Math.min(Math.floor(d*255), 255)
			}
			function getColorAtXY(x, y){
				var x0 = (x - 128) / 128;
				var y0 = (y - 128) / 128;
				var alpha = 0.5 - Math.atan2(y0, x0) / 2 / Math.PI;
				var sector_alpha = alpha*3;
				var sector_number = 2 - Math.floor(sector_alpha);
				sector_alpha = sector_alpha - Math.floor(sector_alpha);
				var distance = Math.sqrt(x0 * x0 + y0*y0) * dist_mult;
				if (sector_number == 0) {
					return {
						"r" : function_up(sector_alpha, distance),
						"b" : function_down(sector_alpha, distance),
						"g" : function_keep(sector_alpha, distance)
					};
				}
				if (sector_number == 1) {
					return {
						"g" : function_up(sector_alpha, distance),
						"r" : function_down(sector_alpha, distance),
						"b" : function_keep(sector_alpha, distance)
					};
				}
				return {
					"b" : function_up(sector_alpha, distance),
					"g" : function_down(sector_alpha, distance),
					"r" : function_keep(sector_alpha, distance)
				};
			};
			var canvas = document.getElementById("myCanvas");
			canvas.addEventListener('mousedown', function(e) {
				const rect = canvas.getBoundingClientRect();
				const x = e.clientX - rect.left;
				const y = e.clientY - rect.top;
				const color = getColorAtXY(x, y);
				const rgb = '#' + componentToHex(color.r) + componentToHex(color.g) + componentToHex(color.b);
				document.body.style.background = rgb;
				document.getElementById('color').value = rgb;
			}, false)
			var ctx = canvas.getContext("2d");
			var canvasData = ctx.getImageData(0, 0, 256, 256);
			var dist_mult = 2 / Math.sqrt(2);
			var index = 0;
			for (var y = 0; y < 256; y++) {
				for (var x = 0; x < 256; x++) {
					var color = getColorAtXY(x, y);
					canvasData.data[index++] = color.r;
					canvasData.data[index++] = color.g;
					canvasData.data[index++] = color.b;
					canvasData.data[index++] = 255;
				}
			}
			ctx.putImageData(canvasData, 0, 0)
		</script>
	"""


def get_html(path):
	content = "<p>Request: %s</p>" % path
	content += "<body>"
	content += color_picker()
	content += "<ul>Texture List:"
	for key, value in paths.items():
		content += "<li><a href='%s'>%s</a></li>" % (key, key)
	content += "</ul>"
	content += "</body></html>"
	return content

class MyServer(BaseHTTPRequestHandler):
	def do_GET(self):
		path = self.path
		if path.endswith(".png"):
			content = get_png(path)
			self.send_response(200)
			self.send_header("Content-type", "image/png")
			self.end_headers()
			self.wfile.write(content)
		else:
			content = get_html(path)
			self.send_response(200)
			self.send_header("Content-type", "text/html")
			self.end_headers()
			self.wfile.write(bytes(content, "utf-8"))

if __name__ == "__main__":
	scan()
	webServer = HTTPServer((hostName, serverPort), MyServer)
	print("Server started http://%s:%s" % (hostName, serverPort))

	try:
		webServer.serve_forever()
	except KeyboardInterrupt:
		pass

	webServer.server_close()
	print("Server stopped.")
