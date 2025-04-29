#!/usr/bin/env ruby

# Settings
BLOCK_SIZE = 2048
VOLUME_PATH = "/Volumes/LG Recorder"
FILES_TO_COPY = [
  "00000001REC/0000000100000001.TS"
]

# Load resume offset for a file
def load_offset(dest_path)
  offset_file = "#{dest_path}.offset"
  if File.exist?(offset_file)
    File.read(offset_file).to_i
  else
    0
  end
end

# Save resume offset for a file
def save_offset(dest_path, offset)
  File.write("#{dest_path}.offset", offset.to_s)
end

# Wait for the DVD volume to appear
def wait_for_volume
  until File.directory?(VOLUME_PATH)
    puts "[INFO] Waiting for DVD to mount at #{VOLUME_PATH}..."
    sleep 5
  end
end

# Read one file incrementally
def read_with_resume(source_path, dest_path)
  offset = load_offset(dest_path)
  puts "[INFO] Starting/resuming #{File.basename(dest_path)} at byte offset #{offset}"

  File.open(source_path, "rb") do |source|
    source.seek(offset)
    File.open(dest_path, "ab") do |dest|
      loop do
        data = source.read(BLOCK_SIZE)
        break if data.nil? || data.empty?

        dest.write(data)
        offset += data.bytesize
        save_offset(dest_path, offset)

        print "\r[INFO] #{File.basename(dest_path)} -> #{offset / 1024 / 1024} MB", flush: true
      end
    end
  end
end

# Main recovery loop
def recover_files
  loop do
    wait_for_volume

    FILES_TO_COPY.each do |relative_path|
      full_source = File.join(VOLUME_PATH, relative_path)
      full_dest = File.basename(relative_path)  # Save output in current folder

      if File.exist?(full_source)
        begin
          puts "\n[INFO] Recovering #{relative_path}"
          read_with_resume(full_source, full_dest)
        rescue => e
          puts "\n[WARN] Error during read: #{e.message}. Will retry..."
          sleep 5
        end
      else
        puts "[WARN] File not found: #{relative_path} - waiting for next connection"
      end
    end
  end
end

# <- THIS was missing before:
recover_files
