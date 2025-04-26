#!/usr/bin/env ruby

BLOCK_SIZE = 2048
DEVICE_PATH = "/dev/rdisk9"
OUTPUT_PATH = "dvd_recovered.iso"
OFFSET_FILE = "dvd.offset"

def load_offset
  if File.exist?(OFFSET_FILE)
    File.read(OFFSET_FILE).to_i
  else
    0
  end
end

def save_offset(offset)
  File.write(OFFSET_FILE, offset.to_s)
end

def wait_for_device(path)
  until File.exist?(path)
    puts "[INFO] Waiting for #{path} to appear..."
    sleep 5
  end
end

def read_dvd_incrementally
  offset = load_offset
  puts "[INFO] Starting/resuming at byte offset #{offset}"

  loop do
    wait_for_device(DEVICE_PATH)

    begin
      File.open(DEVICE_PATH, "rb") do |dvd|
        dvd.seek(offset)
        File.open(OUTPUT_PATH, "ab") do |output|
          loop do
            data = dvd.read(BLOCK_SIZE)
            break if data.nil? || data.empty?

            output.write(data)
            offset += data.bytesize
            save_offset(offset)

            print "\r[INFO] Read #{offset / 1024 / 1024} MB", flush: true
          end
        end
      end
    rescue => e
      puts "\n[WARN] Read error: #{e.message}. Will retry..."
      sleep 3
    end
  end
end

read_dvd_incrementally
