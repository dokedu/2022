# create file ./schema.sql

File.open("schema.sql", "w") {|f| f.write("-- generated file") }

# for each file in ./migrations/*.sql append it to schema.sql

files = Dir.glob("./migrations/*.sql")

files.each do |file|
    File.open("schema.sql", "a") {|f| f.write(File.read(file)) }
end