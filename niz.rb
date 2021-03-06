#!/usr/bin/env ruby
require "hid_api" # gem install hid_api
require "pp"
require "timeout"

class NiZ
	Keymap = Struct.new(:level, :key_id, :hwcode) do
		def self.with(level:, key_id:, hwcode:)
			self.new(level, key_id, hwcode)
		end
	end

	HWCODE = {
		0 => '', # unmapped value
		1 => 'ESC',
		2 => 'F1',
		3 => 'F2',
		4 => 'F3',
		5 => 'F4',
		6 => 'F5',
		7 => 'F6',
		8 => 'F7',
		9 => 'F8',
		10 => 'F9',
		11 => 'F10',
		12 => 'F11',
		13 => 'F12',
		14 => '`',
		15 => '1',
		16 => '2',
		17 => '3',
		18 => '4',
		19 => '5',
		20 => '6',
		21 => '7',
		22 => '8',
		23 => '9',
		24 => '0',
		25 => '-',
		26 => '=',
		27 => 'BS',
		28 => 'TAB',
		29 => 'Q',
		30 => 'W',
		31 => 'E',
		32 => 'R',
		33 => 'T',
		34 => 'Y',
		35 => 'U',
		36 => 'I',
		37 => 'O',
		38 => 'P',
		39 => '[',
		40 => ']',
		41 => '\\',
		42 => 'Caps Lock',
		43 => 'A',
		44 => 'S',
		45 => 'D',
		46 => 'F',
		47 => 'G',
		48 => 'H',
		49 => 'J',
		50 => 'K',
		51 => 'L',
		52 => ';',
		53 => '\'',
		54 => 'RET',
		55 => 'L-Shift',
		56 => 'Z',
		57 => 'X',
		58 => 'C',
		59 => 'V',
		60 => 'B',
		61 => 'N',
		62 => 'M',
		63 => ',',
		64 => '.',
		65 => '/',
		66 => 'R-Shift',
		67 => 'L-CTRL',
		68 => 'Left-Super',
		69 => 'L-Alt',
		70 => 'Space',
		71 => 'R-Alt',
		72 => 'Right-Super',
		73 => 'ContextMenu',
		74 => 'R-Ctrl',
		75 => 'Wakeup',
		76 => 'Sleep',
		77 => 'Power',
		78 => 'PriSc',
		79 => 'SclLk',
		80 => 'Pause',
		81 => 'Ins',
		82 => 'Home',
		83 => 'PageUp',
		84 => 'Del',
		85 => 'End',
		86 => 'PageDown',
		87 => 'Up Arrow',
		88 => 'Left Arrow',
		89 => 'Down Arrow',
		90 => 'Right Arrow',
		91 =>  'Num Lock',
		92 => '(/)',
		93 => '(*)',
		94 => '(7)',
		95 => '(8)',
		96 => '(9)',
		97 => '(4)',
		98 => '(5)',
		99 => '(6)',
		100 =>'(1)',
		101 =>'(2)',
		102 =>'(3)',
		103 =>'(0)',
		104 =>'(.)',
		105 =>'(-)',
		106 =>'(+)',
		107 =>'(Enter)',
		108 => 'Media Next Track',
		109 => 'Media Previous Track',
		110 => 'Media Stop',
		111 => 'Media Play/Pause',
		112 => 'Media Mute',
		113 => 'Media VolumeUp',
		114 => 'Media VolumeDn',
		115 => 'Media Select',
		116 => 'WWW Email',
		117 => 'Media Calculator',
		118 => 'Media My Computer',
		119 => 'WWW Search',
		120 => 'WWW Home',
		121 => 'WWW Back',
		122 => 'WWW Forward',
		123 => 'WWW Stop',
		124 => 'WWW Refresh',
		125 => 'WWW Favorites',
		126 => 'Mouse Mouse Left',
		127 => 'Mouse Mouse Right',
		128 => 'Mouse Mouse Up',
		129 => 'Mouse Mouse Down',
		130 => 'Mouse Key Left',
		131 => 'Mouse Key Right',
		132 => 'Mouse Key Middle',
		133 => 'Mouse Wheel Up',
		134 => 'Mouse Wheel Dn',
		135 => 'Backlight Switch',
		136 => 'Backlight Macro',
		137 => 'Demonstrate',
		138 => 'Star shower',
		139 => 'Riffle',
		140 => 'Demo Stop',
		141 => 'Breathe',
		142 => 'Breathe Sequence-',
		143 => 'Breathe Sequence+',
		144 => 'Backlight Lightness-',
		145 => 'Backlight Lightness+',
		146 => 'Sunset or Relax/Aurora',
		147 => 'Color Breathe',
		148 => 'Back Color Exchange',
		149 => 'Adjust Trigger Point',
		150 => 'Keyboard Lock',
		151 => 'Shift&Up',
		152 => 'Ctrl&Caps Exchange',
		153 => 'WinLock',
		154 => 'MouseLock',
		155 => 'Win/Mac Exchange',
		156 => 'R-Fn',
		157 => 'Mouse Unit Pixel',
		158 => 'Mouse Unit Time',
		159 => 'Programmable keyboard',
		160 => 'Backlight Record1',
		161 => 'Backlight Record2',
		162 => 'Backlight Record3',
		163 => 'Backlight Record4',
		164 => 'Backlight Record5',
		165 => 'Backlight Record6',
		166 => 'L-Fn',
		167 => 'Wire/Wireless exchange',
		168 => 'BTD1',
		169 => 'BTD2',
		170 => 'BTD3',
		171 => 'Game',
		172 => 'ECO',
		173 => 'Mouse First Delay',
		174 => 'Key Repeat Rate',
		175 => 'Key Response Delay',
		176 => 'USB Report Rate',
		177 => 'Key Scan Period',
		178 => 'unknown',
		179 => 'unknown',
		180 => 'unknown',
		181 => 'unknown',
		182 => 'unknown',
		183 => 'unknown',
		184 => 'unknown',
		185 => 'unknown',
		186 => 'unknown',
		187 => 'unknown',
		188 => 'unknown',
		189 => 'unknown',
		190 => 'unknown',
		191 => 'unknown',
		192 => 'unknown',
		193 => 'unknown',
		194 => 'unknown',
		195 => 'unknown',
		196 => 'unknown',
		197 => 'unknown',
		198 => 'unknown',
		199 => 'Mouse Left Double Click',
		200 => 'unknown',
		201 => 'unknown',
		202 => 'unknown',
		203 => 'unknown',
		204 => '<>|',
		205 => 'unknown',
		206 => 'unknown',
		207 => 'unknown',
		208 => 'unknown',
		209 => 'unknown',
		210 => 'unknown',
		211 => 'unknown',
		212 => 'unknown',
		213 => 'unknown',
		214 => 'unknown',
		215 => 'unknown',
		216 => 'unknown',
		217 => 'unknown',
		218 => 'unknown',
		219 => 'unknown',
		220 => 'unknown',
		221 => 'unknown',
		222 => 'unknown',
		223 => 'unknown',
		224 => 'unknown',
		225 => 'unknown',
		226 => 'unknown',
		227 => 'unknown',
		228 => 'unknown',
		229 => 'unknown',
		230 => 'unknown',
		231 => 'unknown',
		232 => 'unknown',
		233 => 'unknown',
		234 => 'unknown',
		235 => 'unknown',
		236 => 'unknown',
		237 => 'unknown',
		238 => 'unknown',
		239 => 'unknown',
		240 => 'unknown',
		241 => 'unknown',
		242 => 'unknown',
		243 => 'unknown',
		244 => 'unknown',
		245 => 'unknown',
		246 => 'unknown',
		247 => 'unknown',
		248 => 'unknown',
		249 => 'unknown',
		250 => 'unknown',
		251 => 'unknown',
		252 => 'unknown',
		253 => 'unknown',
		254 => 'unknown',
		255 => 'unknown',
	}

	COMMAND_READ_SERIAL = 0x10
	COMMAND_CALIB = 0xda
	COMMAND_INITIAL_CALIB = 0xdb
	COMMAND_PRESS_CALIB = 0xdd
	COMMAND_KEYLOCK = 0xd9 # 0xd9 0x00 lock / 0xd9 0x01 unlock
	COMMAND_PRESS_CALIB_DONE = 0xde
	COMMAND_XXX_DATA = 0xe0 # TODO maybe macro
	COMMAND_READ_XXX = 0xe2 # TODO maybe macro
	COMMAND_READ_COUNTER = 0xe3
	COMMAND_XXX_END = 0xe6
	COMMAND_KEY_DATA = 0xf0
	COMMAND_WRITE_ALL = 0xf1
	COMMAND_READ_ALL = 0xf2
	COMMAND_DATA_END = 0xf6
	COMMAND_VERSION = 0xf9

	def self.name_from_hwcode(hwcode)
		if hwcode
			HWCODE[hwcode]
		else
			nil
		end
	end

	def self.mapping_from_array(read_all)
		keymap = read_all.reduce({}) {|r, i|
			(r[i.level] ||= {})[i.key_id] = i.hwcode
			r
		}
	end

	def self.array_from_mapping(keymap)
		# TODO
	end

	def initialize
	end

	def open
		@device = HidApi.open(0x0483, 0x512A)
		# ensure hid open
		@version = version
	end

	def keycount
		@version[/^\d+/].to_i
	end

	def close
		@device.close if @device
		@device = nil
	end

	def recv_report(length, timeout=100)
		buffer = FFI::Buffer.new(1, length)
		len = HidApi.hid_read_timeout(@device, buffer, buffer.length, timeout)
		case len
		when -1
			raise HidApi::HidError, "unknown error"
		when 0
			raise HidApi::HidError, "timeout"
		else
			buffer.get_bytes(0, len)
		end
	end

	def send_command(command, data="")
		report_id = 0x00
		buf = String.new("\0" * 65, encoding: 'BINARY')
		buf[0] = report_id.chr
		buf[1, 2] = [command].pack("n")
		buf[3, [62, data.size].min] = data
		@device.write(buf)
	end

	def recv_data(timeout=100)
		# report_id may not be included
		recv_report(64)
	end

	def version
		send_command(COMMAND_VERSION)
		bytes = recv_data
		_command, version = bytes.unpack("nA*")
		version
	end

	def read_all(&block)
		keymaps = []
		send_command(COMMAND_READ_ALL)
		count = 0
		loop do  # expect 66 * 3 (layers) = 198 count
			bytes = recv_data
			break if bytes[0] != "\x00"
			_command, level, key_id, _unknown, hwcode, *_rest = *bytes.unpack("nCCa2CC*")
			keymaps << Keymap.new(level-1, key_id, hwcode)
			# puts "l=%d, key=% 3d hwcode=% 4d %p %s " % [level-1, key_id, hwcode, _unknown, _rest.map {|i| "%02x" % i }.join(" ")]
			block.call(count, keymaps.last)
			count += 1
		end
		keymaps
	end

	def read_counter
		all_counts = []
		send_command(COMMAND_READ_COUNTER)
		loop do
			bytes = recv_data
			break if bytes[0] != "\x00"
			_command, _unknown, *counts = *bytes.unpack("ncV*")
			all_counts.concat(counts)
		end
		all_counts
	end

	def keylock
		send_command(COMMAND_KEYLOCK, "\x00")
	end

	def keyunlock
		send_command(COMMAND_KEYLOCK, "\x01")
	end

	def calibration_init
		send_command(COMMAND_INITIAL_CALIB)
	end

	def calibration_press
		send_command(COMMAND_PRESS_CALIB)
		p recv_data
	end

	# reset all mapping
	# and write mapping
	# you should write all keymap everytime.
	def write_all(keymap, &block)
		if keymap.is_a? Array
			keymap = all.reduce({}) {|r, i|
				(r[i.level] ||= {})[i.key_id] = i.hwcode
				r
			}
		end

		send_command(COMMAND_WRITE_ALL)
		count = 0
		[0, 1, 2].each do |level|
			(1..self.keycount).each do |key_id|
				hwcode = keymap[level][key_id]

				data = [
					level + 1,
					key_id,
					hwcode && hwcode.nonzero? ? "\x00\x01" : "\x00\x00",
					hwcode || 0
				].pack("CCa2C")
				block.call(count)
				send_command(COMMAND_KEY_DATA, data)
				count += 1
			end
		end
		send_command(COMMAND_DATA_END, COMMAND_DATA_END.chr * 62)
	end
end

p $0, __FILE__
if $0 == __FILE__
	require 'progress_bar'
	require 'terminal-table'
	require 'optparse'
	options = ARGV.getopts("", "mode:read")

	mode = options["mode"]

	niz = NiZ.new
	Timeout.timeout(1) do
		begin
			niz.open
		rescue => e
			$stderr.puts "#{e.inspect} retrying open device..."
			retry
		end
	end

	puts "Version: #{niz.version}"
	puts "#{niz.keycount} keys"

	case mode
	when 'read'
		puts "Reading key mapping..."
		progress = ProgressBar.new(niz.keycount * 3)
		read_all = niz.read_all do |count, keymap|
			progress.increment!
		end

		puts "Reading key counter..."
		counts = niz.read_counter

		mapping = NiZ.mapping_from_array(read_all)

		table = Terminal::Table.new(
			title: "#{niz.version} #{niz.keycount} keys",
			headings: ['Key ID', 'Normal', 'Right Fn', 'Left Fn', 'Count'],
		)

		format_key = lambda do |hwcode|
			name = NiZ.name_from_hwcode(hwcode)
			if hwcode && hwcode.nonzero?
				"[% 3d] %s" % [hwcode, name]
			else
				""
			end
		end

		niz.keycount.times do |i|
			key_id = i + 1
			
			case key_id
			when 16, 30, 43, 56
				table << :separator
			end

			table << [
				key_id,
				format_key[mapping[0][key_id]],
				format_key[mapping[1][key_id]],
				format_key[mapping[2][key_id]],
				counts[i]
			]
		end
		puts table
	when 'keylock'
		niz.keylock
		puts "keys are locked"
	when 'keyunlock'
		niz.keyunlock
		puts "keys are unlocked"
	else
		$stderr.puts "unknown mode: #{mode}"
	end
end
