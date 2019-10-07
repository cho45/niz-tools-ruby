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
		42 => '', # TODO
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
		68 => 'Super',
		69 => 'L-Alt',
		70 => 'Space',
		71 => 'R-Alt',
		72 => '', # TODO
		73 => '', # TODO
		74 => 'R-Ctrl',
		75 => '', # TODO
		76 => '', # TODO
		77 => '', # TODO
		78 => 'PriSc',
		79 => 'SclLk',
		80 => 'Pause',
		81 => 'Ins',
		82 => 'Home',
		83 => '', # TODO
		84 => 'Del',
		85 => 'End',
		86 => '', # TODO
		87 => 'Up Arrow',
		88 => 'Left Arrow',
		89 => 'Down Arrow',
		90 => 'Right Arrow',
		126 => 'Mouse Mouse Left',
		127 => 'Mouse Mouse Right',
		128 => 'Mouse Mouse Up',
		129 => 'Mouse Mouse Down',
		130 => 'Mouse Key Left',
		131 => 'Mouse Key Right',
		132 => 'Mouse Key Middle',
		144 => 'Backlight Lightness-',
		149 => 'Adjust Trigger Point',
		152 => 'Ctrl/CapsLock exchange',
		153 => 'winlock',
		155 => 'win/mac exchange',
		156 => 'R-Fn',
		157 => 'Mouse Unit Pixel',
		158 => 'Mouse Unit Time',
		159 => 'Programmable keyboard',
		166 => 'L-Fn',
		167 => 'Wire/Wireless exchange',
		168 => 'BTD1',
		169 => 'BTD2',
		170 => 'BTD3',
		171 => 'Game',
		172 => 'ECO',
		175 => 'Key Response Delay',
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
		niz.keycount.times do |i|
			key_id = i + 1
			
			case key_id
			when 16, 30, 43, 56
				table << :separator
			end

			table << [
				key_id,
				NiZ.name_from_hwcode(mapping[0][key_id]),
				NiZ.name_from_hwcode(mapping[1][key_id]),
				NiZ.name_from_hwcode(mapping[2][key_id]),
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
