local Connect = torch.class("hypero.Connect")

function Connect:__init(config)
   self.schema = config.schema or 'hyper'
   assert(torch.type(self.schema) == 'string')
   assert(self.schema ~= '')
   self.dbconn = config.dbconn or hypero.Postgres(config)
   self:create()
end
hypero.connect = hypero.Connect

function Connect:battery(batName, verDesc, verbose)
   local bat = hypero.Battery(self, batName, verbose)
   bat:version(verDesc)
   return bat
end

function Connect:close()
   self.dbconn:close()
end

function Connect:create()
   -- create the schema and tables if they don't already exist
   self.dbconn:execute(string.gsub([[
   CREATE SCHEMA IF NOT EXISTS $schema$;

   CREATE TABLE IF NOT EXISTS $schema$.battery (
      bat_id 		BIGSERIAL,
      bat_name   	VARCHAR(255),
      bat_time 	TIMESTAMP DEFAULT now(),
      PRIMARY KEY (bat_id),
      UNIQUE (bat_name)
   );

   CREATE TABLE IF NOT EXISTS $schema$.version (
      ver_id 		BIGSERIAL,
      bat_id		INT8,
      ver_desc 	VARCHAR(255),
      ver_time	TIMESTAMP DEFAULT now(),
      PRIMARY KEY (ver_id),
      FOREIGN KEY (bat_id) REFERENCES $schema$.battery (bat_id),
      UNIQUE (bat_id, ver_desc)
   );

   CREATE TABLE IF NOT EXISTS $schema$.experiment (   
      hex_id      BIGSERIAL,
      bat_id      INT8,
      ver_id		INT8,
      hex_time 	TIMESTAMP DEFAULT now(),
      FOREIGN KEY (bat_id) REFERENCES $schema$.battery(bat_id),
      FOREIGN KEY (ver_id) REFERENCES $schema$.version(ver_id),
      PRIMARY KEY (hex_id)
   );

   CREATE TABLE IF NOT EXISTS $schema$.param (
      hex_id		INT8,
      param_name	VARCHAR(255),
      param_val	JSON, 
      PRIMARY KEY (hex_id, param_name),
      FOREIGN KEY (hex_id) REFERENCES $schema$.experiment (hex_id)
   );

   CREATE TABLE IF NOT EXISTS $schema$.metadata (
      hex_id		INT8,
      meta_name	VARCHAR(255),
      meta_val 	JSON,
      PRIMARY KEY (hex_id, meta_name),
      FOREIGN KEY (hex_id) REFERENCES $schema$.experiment (hex_id)
   );

   CREATE TABLE IF NOT EXISTS $schema$.result (
      hex_id		INT8,
      result_name	VARCHAR(255),
      result_val	JSON,
      PRIMARY KEY (hex_id, result_name),
      FOREIGN KEY (hex_id) REFERENCES $schema$.experiment (hex_id)
   );   
   ]],"%$schema%$", self.schema))
end

--[[ Decorator methods ]]--

function Connect:executeMany(...)
   return self.dbconn:executeMany(...)
end

function Connect:execute(...)
   return self.dbconn:execute(...)
end

function Connect:fetch(...)
   return self.dbconn:fetch(...)
end

function Connect:fetchOne(...)
   return self.dbconn:fetchOne(...)
end

function Connect:close(...)
   return self.dbconn:close(...)
end
