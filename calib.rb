#!/usr/bin/env ruby

require 'sinatra'
require 'launchy'
require './niz.rb'

configure do
	# Launchy.open("http://%s:%s/" % [settings.bind, settings.port])
end

get '/' do
	erb :index
end

post '/api/version' do
	content_type :text

	$niz = NiZ.new
	Timeout.timeout(1) do
		begin
			$niz.open
		rescue => e
			$stderr.puts "#{e.inspect} retrying open device..."
			retry
		end
	end

	$niz.version
end

post '/api/keylock' do
	$niz.keylock
	content_type :text
	"ok"
end

post '/api/keyunlock' do
	$niz.keyunlock
	content_type :text
	"ok"
end

post '/api/calibration-init' do
	$niz.calibration_init
	content_type :text
	"ok"
end

post '/api/calibration-press' do
	$niz.calibration_press
	content_type :text
	"ok"
end

__END__
@@ index
<!DOCTYPE html>
<html>
<head>
	<meta content="width=device-width,initial-scale=1,minimal-ui" name="viewport">
	<title>NiZ Calibrator</title>
	<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700,400italic|Material+Icons">
	<link rel="stylesheet" href="https://unpkg.com/vue-material/dist/vue-material.min.css">
	<link rel="stylesheet" href="https://unpkg.com/vue-material/dist/theme/default.css">
	<style>
		.md-app-content {
			width: 500px;
			margin: 0 auto;
		}

		.md-layout {
			align-items: center;
		}
	</style>
</head>
<body>
	<div id="app">
		<md-app>
			<md-app-content>
				<div class="md-layout">
					<div class="md-layout-item">
						<md-button @click="getVersion" class="md-raised">Connect</md-button>
					</div>
					<div class="md-layout-item">
						{{version || 'Not Connected'}}
					</div>
				</div>
				<div class="md-layout">
					<div class="md-layout-item">
						<md-button @click="keylock" :disabled="!connected" class="md-raised">Key Lock</md-button>
						<md-button @click="keyunlock" :disabled="!connected" class="md-raised">Key Unlock</md-button>
					</div>
					<div class="md-layout-item">
						Key is {{ locked? 'Locked' : 'Unlocked' }}
					</div>
				</div>
				<hr>
				<div class="md-layout">
					<div class="md-layout-item">
						Do not press any key and:
						<md-button @click="calibrationInit" :disabled="!(connected && locked)" class="md-raised">Calibration Init</md-button>
					</div>
					<div class="md-layout-item">
						Press some key and:
						<md-button @click="calibrationPress" :disabled="!(connected && locked)" class="md-raised">Caliburation Press</md-button>
					</div>
				</div>
			</md-app-content>
		</md-app>
	</div>
	<script src="https://unpkg.com/vue@2.6.10/dist/vue.js"></script>
	<script src="https://unpkg.com/vue-material/dist/vue-material.min.js"></script>
	<script>
		Vue.use(VueMaterial.default);

		const App = new Vue({
			el: '#app',
			data: {
				version: '',
				locked: false,
			},

			methods: {
				getVersion: async function () {
					this.version = await (await fetch('/api/version', { method: 'POST' })).text();
				},

				keylock: async function () {
					const res = await (await fetch('/api/keylock', { method: 'POST' })).text();
					if (res === 'ok') {
						this.locked = true;
					}
				},

				keyunlock: async function () {
					const res = await (await fetch('/api/keyunlock', { method: 'POST' })).text();
					if (res === 'ok') {
						this.locked = false;
					}
				},

				calibrationInit: async function () {
					const res = await (await fetch('/api/calibration-init', { method: 'POST' })).text();
				},

				calibrationPress: async function () {
					const res = await (await fetch('/api/calibration-press', { method: 'POST' })).text();
				},
			},

			computed: {
				connected: function () {
					return !!this.version;
				}
			},

			mounted: function () {
			}
		});
	</script>
</body>
</html>
