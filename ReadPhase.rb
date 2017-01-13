#!/usr/bin/env ruby
#-----------------------
#
# Ruby script to read out PHASE1, including weather station
#
# Authors Erik Kallen, Jan Stegenga
#
# Creates 4 files every so many minutes; date/time is in the file name
# 1 ADC           binary       3-5 traces per s
# 2 SPECTRUM      csv          1 /s
# 3 WEATHER       txt/json     1 /30s
# 4 LIVEDEADTIME  csv          1 /s
#
# to get data off the PHASE type:
#
# ssh root@10.0.0.1
# for i in $(seq 58 516); do wget http://10.0.0.1/data/$\{i\}.json; sleep 2; done
# for i in {58..516}; do wget http://10.0.0.1/data/${i}.json; sleep 2; done
#
#-----------------------
require 'socket'

#threads
def weather_thread( interval = 15 )
  sock_weather = TCPServer.new 5000
  fid_WEATHER = File.new( "/Users/demo/Desktop/PHASE/" + "WEATHER_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".txt" , "w" )
  
  client = sock_weather.accept
  interval = 15*60 #second
  interval_start = Time.now.to_i
  while true
    line = client.gets
    if Time.now.to_i > interval_start + interval  
      interval_start = Time.now.to_i
      fid_WEATHER = File.new( "/Users/demo/Desktop/PHASE/" + "WEATHER_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".txt" , "w" )
    end
    fid_WEATHER.write( "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line )
    $stderr.puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line[0,40]
  end
  client.close
end

def phase_thread( interval = 15 )
  hostname = '10.0.0.1'
  port = 6000
  sock = TCPSocket.open( hostname, port )
  fid_MSSPE = File.new( "/Users/demo/Desktop/PHASE/" + "SPECTRA_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
  fid_LDT = File.new( "/Users/demo/Desktop/PHASE/" + "LDT_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
  #fid_ADC = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
  fid_ADC2 = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".dat" , "wb" )
  interval = 15*60 #second
  interval_start = Time.now.to_i
  while true
    line = sock.gets
    if Time.now.to_i > interval_start + interval  
      interval_start = Time.now.to_i
      $stderr.puts "Interval ended at " + Time.now.strftime('%Y%m%d-%H:%M:%S_%L')
      fid_MSSPE = File.new( "/Users/demo/Desktop/PHASE/" + "SPECTRA_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
      fid_LDT = File.new( "/Users/demo/Desktop/PHASE/" + "LDT_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
      #fid_ADC = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
      fid_ADC2 = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".dat" , "wb" )
    end

    if line.include? "MSSPE"
      # puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line
      $stderr.puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line[0,40] 
      fid_MSSPE.write( "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line )
    elsif line.include? "ADC" 
      values = line.split(",")    #create list of items
      values = values.drop(3)     #ignore first 3 numbers ('ADC', id, 1024)
      values.pop                  #ignore last item ('*CP')
      values = values.map(&:to_i) #items to integers
      #puts values
      n_written = fid_ADC2.syswrite( values.pack("S*") )
      # $stderr.puts n_written
      # fid_ADC.write( "#{Time.now.strftime('%Y-%m-%d %H:%M:%S:%L')}, " + line )
    else # LIVEDEADTIME
      # $stderr.puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line[0,40] 
      fid_LDT.write( "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line )
    end
  end
end


t_w = Thread.new{weather_thread()}
t_p = Thread.new{phase_thread()}
sleep(2)
#start weather_fetcher by a command line call
t_1 = Thread.new{%x[ /Users/demo/projects//weather_fetcher/src/weather_fetcher -i 30 -t /dev/tty.usbserial-FTVXKW6R ]}

while true
  sleep(1)
end
return
#-----------------------
#end of threads
#-----------------------






#-----------------------
# old code, without threading
#-----------------------

hostname = '10.0.0.1'
port = 6000
sock = TCPSocket.open( hostname, port )
fid_MSSPE = File.new( "/Users/demo/Desktop/PHASE/" + "SPECTRA_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
#fid_ADC = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
fid_ADC2 = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".dat" , "wb" )
interval = 15*60 #second
interval_start = Time.now.to_i

#$stderr.puts value
line = client.gets
$stderr.puts line
client.close

while true
  line = sock.gets
  if Time.now.to_i > interval_start + interval  
    interval_start = Time.now.to_i
    $stderr.puts "Interval ended at " + Time.now.strftime('%Y%m%d-%H:%M:%S_%L')
    fid_MSSPE = File.new( "/Users/demo/Desktop/PHASE/" + "SPECTRA_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
    #fid_ADC = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".csv" , "w" )
    fid_ADC2 = File.new( "/Users/demo/Desktop/PHASE/" + "ADC_" + "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}" + ".dat" , "wb" )
  end

  if line.include? "MSSPE"
    # puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line
    $stderr.puts "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line[0,40] 
    fid_MSSPE.write( "#{Time.now.strftime('%Y%m%d-%H%M%S_%L')}, " + line )
  else
    values = line.split(",")    #create list of items
    values = values.drop(3)     #ignore first 3 numbers ('ADC', id, 1024)
    values.pop                  #ignore last item ('*CP')
    values = values.map(&:to_i) #items to integers
    #puts values
    n_written = fid_ADC2.syswrite( values.pack("S*") )
    # $stderr.puts n_written
    # fid_ADC.write( "#{Time.now.strftime('%Y-%m-%d %H:%M:%S:%L')}, " + line )
  end
end
