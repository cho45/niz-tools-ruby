#!/usr/bin/env ruby

require 'sinatra'
require './niz.rb'

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
	<title>NiZ Calibrator</title>
</head>
<body>
	<div id="app">
		<button @click="getVersion">Get Version</button>
		<input readonly :value="version">
		<button @click="keylock" :disabled="!connected">Key Lock</button>
		<button @click="keyunlock" :disabled="!connected">Key Unlock</button>
		<p>Key is {{ locked? 'Locked' : 'Unlocked' }}</p>
		<button @click="calibrationInit" :disabled="!(connected && locked)">Calibration Init</button>
		<button @click="calibrationPress" :disabled="!(connected && locked)">Caliburation Press</button>
	</div>
	<script src="https://unpkg.com/vue@2.6.10/dist/vue.js"></script>
	<script>

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
