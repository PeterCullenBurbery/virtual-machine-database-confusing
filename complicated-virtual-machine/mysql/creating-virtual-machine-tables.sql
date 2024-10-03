-- Step 1: Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS virtual_machine_database;

-- Step 2: Use the created database
USE virtual_machine_database;


-- 1. Create the virtualization_software table
CREATE TABLE virtualization_software (
    virtualization_software_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    virtualization_software    mediumtext NOT NULL,
    company                    mediumtext NOT NULL,
    CONSTRAINT uq_software_company UNIQUE (virtualization_software(255), company(255)),

    -- Additional columns for note and dates
    note                       mediumtext,  -- General-purpose note field
    date_created               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated               TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);
-- 2. Create the operating_system_category table
CREATE TABLE operating_system_category (
    operating_system_category_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    operating_system_category    mediumtext NOT NULL,
    description                  MEDIUMTEXT,
    CONSTRAINT uq_category UNIQUE (operating_system_category(255)),

    -- Additional columns for note and dates
    note                         MEDIUMTEXT,  -- General-purpose note field
    date_created                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated                 TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);
-- 3. Create the operating_system table with operating_system_category_id
CREATE TABLE operating_system (
    operating_system_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    operating_system MEDIUMTEXT NOT NULL,
    operating_system_category_string MEDIUMTEXT NOT NULL,
    operating_system_category_id BINARY(16),  -- New column for foreign key reference
    
    CONSTRAINT fk_os_category FOREIGN KEY (operating_system_category_id)
        REFERENCES operating_system_category (operating_system_category_id),
    CONSTRAINT uq_os_category UNIQUE (operating_system(255), operating_system_category_string(255)),  -- Prefix length for index

    -- Additional columns for note and dates
    note MEDIUMTEXT,  -- General-purpose note field
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- 3. Create the operating_system_category table
CREATE TABLE operating_system_category (
    operating_system_category_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    operating_system_category    VARCHAR(1000) NOT NULL,
    description                  VARCHAR(4000),
    CONSTRAINT uq_category UNIQUE (operating_system_category),

    -- Additional columns for note and dates
    note                         VARCHAR(4000),  -- General-purpose note field
    date_created                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated                 TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- 4. Create the operating_system_category_to_operating_system joining table
CREATE TABLE operating_system_category_to_operating_system (
    mapping_id                   BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    operating_system_id          BINARY(16) NOT NULL,
    operating_system_category_id BINARY(16) NOT NULL,
    CONSTRAINT fk_operating_system FOREIGN KEY (operating_system_id)
        REFERENCES operating_system (operating_system_id),
    CONSTRAINT fk_operating_system_category FOREIGN KEY (operating_system_category_id)
        REFERENCES operating_system_category (operating_system_category_id),
    CONSTRAINT uq_os_category_mapping UNIQUE (operating_system_id, operating_system_category_id),

    -- Additional columns for note and dates
    note                         MEDIUMTEXT,  -- General-purpose note field
    date_created                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated                 TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- Modify the operating_system_instance table to include operating_system_id
CREATE TABLE operating_system_instance (
    operating_system_instance_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    operating_system_instance_string MEDIUMTEXT NOT NULL,

    operating_system_string MEDIUMTEXT NOT NULL,  -- String for operating system    
    version VARCHAR(1000) NOT NULL,  -- Version of the operating system
    iso_image_file                            MEDIUMTEXT,
    operating_system_id BINARY(16),  -- Foreign key reference to operating_system
    -- Foreign key constraint
    CONSTRAINT fk_operating_system_for_operating_system_instance FOREIGN KEY (operating_system_id)
        REFERENCES operating_system (operating_system_id),
    -- Additional columns
    note MEDIUMTEXT,  -- General-purpose note field
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- Create the virtualization_software_instance table linked to virtualization_software
CREATE TABLE virtualization_software_instance (
    virtualization_software_instance_id BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    virtualization_software_string      MEDIUMTEXT NOT NULL,  -- String for virtualization software
    virtualization_software_id          BINARY(16) NOT NULL,  -- Foreign key to virtualization_software
    version                             VARCHAR(1000) NOT NULL,  -- Version of the virtualization software

    CONSTRAINT fk_virtualization_software_for_virtualization_software_instance FOREIGN KEY (virtualization_software_id)
        REFERENCES virtualization_software (virtualization_software_id),

    -- Additional columns for note and dates
    note                                MEDIUMTEXT,  -- General-purpose note field
    date_created                        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated                        TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- 6. Create the virtual_machine table with links to operating_system_instance
CREATE TABLE virtual_machine (
    virtual_machine_id                        BINARY(16) DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    machine_name                              MEDIUMTEXT NOT NULL,
    short_description                         MEDIUMTEXT,
    description                               MEDIUMTEXT,
    virtualization_software_instance_string   MEDIUMTEXT NOT NULL,  -- String for virtualization software instance
    virtualization_software_instance_id       BINARY(16) NOT NULL,
    operating_system_instance_string          MEDIUMTEXT NOT NULL,
    operating_system_instance_id              BINARY(16) NOT NULL,

    -- New columns for cloning
    full_clone_parent_string                  MEDIUMTEXT,
    full_clone_parent_id                      BINARY(16),
    linked_clone_parent_string                MEDIUMTEXT,
    linked_clone_parent_id                    BINARY(16),

    -- Allowing larger values for RAM, processors, and disk size
    ram                                       BIGINT NOT NULL,  -- RAM is in bytes
    number_of_processors                      INT NOT NULL,  -- Allows up to 1000 processors
    cores_per_processor                       INT NOT NULL,  -- Allows up to 1000 cores per processor
    disk_size                                 BIGINT NOT NULL,  -- Disk size is in bytes

    nested_virtualization_enabled             BOOLEAN DEFAULT FALSE NOT NULL,
    
    network_drives_enabled_and_used           BOOLEAN DEFAULT FALSE,
    hard_disk_file                            MEDIUMTEXT,
    shared_clipboard_is_working_and_turned_on BOOLEAN DEFAULT TRUE NOT NULL,

    -- Additional columns for note and dates
    note                                      MEDIUMTEXT,  -- General-purpose note field
    date_created                              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_updated                              TIMESTAMP DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign key constraints
    CONSTRAINT fk_virtualization_software_for_vm FOREIGN KEY (virtualization_software_instance_id)
        REFERENCES virtualization_software_instance (virtualization_software_instance_id),
    CONSTRAINT fk_operating_system_instance_for_vm FOREIGN KEY (operating_system_instance_id)
        REFERENCES operating_system_instance (operating_system_instance_id),
    CONSTRAINT fk_full_clone_parent_for_vm FOREIGN KEY (full_clone_parent_id)
        REFERENCES virtual_machine (virtual_machine_id),
    CONSTRAINT fk_linked_clone_parent_for_vm FOREIGN KEY (linked_clone_parent_id)
        REFERENCES virtual_machine (virtual_machine_id)
);
-- Add comments for RAM, disk size, processors, and cores per processor in virtual_machine
ALTER TABLE virtual_machine MODIFY COLUMN ram BIGINT NOT NULL COMMENT 'RAM is in bytes';
ALTER TABLE virtual_machine MODIFY COLUMN disk_size BIGINT NOT NULL COMMENT 'Disk size is in bytes';
ALTER TABLE virtual_machine MODIFY COLUMN number_of_processors INT NOT NULL COMMENT 'Allows up to 1000 processors';
ALTER TABLE virtual_machine MODIFY COLUMN cores_per_processor INT NOT NULL COMMENT 'Allows up to 1000 cores per processor';

DELIMITER $$

CREATE FUNCTION escape_regex_special_chars(input_string TEXT) RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE escaped_string TEXT;
    SET escaped_string = input_string;
    -- Escape special characters with double backslashes
    SET escaped_string = REPLACE(escaped_string, '\\', '\\\\');
    SET escaped_string = REPLACE(escaped_string, '.', '\\.');
    SET escaped_string = REPLACE(escaped_string, '(', '\\(');
    SET escaped_string = REPLACE(escaped_string, ')', '\\)');
    SET escaped_string = REPLACE(escaped_string, '[', '\
\[');
    SET escaped_string = REPLACE(escaped_string, ']', '\\]');
    SET escaped_string = REPLACE(escaped_string, '{', '\\{');
    SET escaped_string = REPLACE(escaped_string, '}', '\\}');
    SET escaped_string = REPLACE(escaped_string, '*', '\\*');
    SET escaped_string = REPLACE(escaped_string, '+', '\\+');
    SET escaped_string = REPLACE(escaped_string, '?', '\\?');
    SET escaped_string = REPLACE(escaped_string, '^', '\\^');
    SET escaped_string = REPLACE(escaped_string, '$', '\\$');
    SET escaped_string = REPLACE(escaped_string, '|', '\\|');
    SET escaped_string = REPLACE(escaped_string, '/', '\\/');

    RETURN escaped_string;
END$$

DELIMITER ;

DELIMITER $$

-- Trigger to update date_updated for virtualization_software
CREATE TRIGGER trg_set_date_updated_virt_software 
BEFORE UPDATE ON virtualization_software
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for operating_system
CREATE TRIGGER trg_set_date_updated_os 
BEFORE UPDATE ON operating_system
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for operating_system_category
CREATE TRIGGER trg_set_date_updated_os_category 
BEFORE UPDATE ON operating_system_category
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for operating_system_category_to_operating_system
CREATE TRIGGER trg_set_date_updated_os_cat_to_os 
BEFORE UPDATE ON operating_system_category_to_operating_system
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for operating_system_instance
CREATE TRIGGER trg_set_date_updated_os_instance 
BEFORE UPDATE ON operating_system_instance
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for virtual_machine
CREATE TRIGGER trg_set_date_updated_vm 
BEFORE UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

-- Trigger to update date_updated for virtualization_software_instance
CREATE TRIGGER trg_set_date_updated_for_virtualization_instance
BEFORE UPDATE ON virtualization_software_instance
FOR EACH ROW
BEGIN
    SET NEW.date_updated = CURRENT_TIMESTAMP;
END$$

DELIMITER $$

-- Trigger to set full_clone_parent_id from string in virtual_machine before INSERT
CREATE TRIGGER trg_set_full_clone_parent_id_from_string_insert
BEFORE INSERT ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.full_clone_parent_string IS NOT NULL THEN
        SET NEW.full_clone_parent_id = (
            SELECT virtual_machine_id
            FROM virtual_machine
            WHERE NEW.full_clone_parent_string REGEXP CONCAT('^', escape_regex_special_chars(machine_name), '$')
        );
    END IF;
END$$

-- Trigger to set full_clone_parent_id from string in virtual_machine before UPDATE
CREATE TRIGGER trg_set_full_clone_parent_id_from_string_update
BEFORE UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.full_clone_parent_string IS NOT NULL THEN
        SET NEW.full_clone_parent_id = (
            SELECT virtual_machine_id
            FROM virtual_machine
            WHERE NEW.full_clone_parent_string REGEXP CONCAT('^', escape_regex_special_chars(machine_name), '$')
        );
    END IF;
END$$

-- Trigger to set linked_clone_parent_id from string in virtual_machine before INSERT
CREATE TRIGGER trg_set_linked_clone_parent_id_from_string_insert
BEFORE INSERT ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.linked_clone_parent_string IS NOT NULL THEN
        SET NEW.linked_clone_parent_id = (
            SELECT virtual_machine_id
            FROM virtual_machine
            WHERE NEW.linked_clone_parent_string REGEXP CONCAT('^', escape_regex_special_chars(machine_name), '$')
        );
    END IF;
END$$

-- Trigger to set linked_clone_parent_id from string in virtual_machine before UPDATE
CREATE TRIGGER trg_set_linked_clone_parent_id_from_string_update
BEFORE UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.linked_clone_parent_string IS NOT NULL THEN
        SET NEW.linked_clone_parent_id = (
            SELECT virtual_machine_id
            FROM virtual_machine
            WHERE NEW.linked_clone_parent_string REGEXP CONCAT('^', escape_regex_special_chars(machine_name), '$')
        );
    END IF;
END$$

-- Trigger to set operating_system_category_id from string in operating_system before INSERT
CREATE TRIGGER trg_set_os_category_id_from_string_insert
BEFORE INSERT ON operating_system
FOR EACH ROW
BEGIN
    IF NEW.operating_system_category_string IS NOT NULL THEN
        SET NEW.operating_system_category_id = (
            SELECT operating_system_category_id
            FROM operating_system_category
            WHERE NEW.operating_system_category_string REGEXP CONCAT('^', escape_regex_special_chars(operating_system_category), '$')
        );
    END IF;
END$$

-- Trigger to set operating_system_category_id from string in operating_system before UPDATE
CREATE TRIGGER trg_set_os_category_id_from_string_update
BEFORE UPDATE ON operating_system
FOR EACH ROW
BEGIN
    IF NEW.operating_system_category_string IS NOT NULL THEN
        SET NEW.operating_system_category_id = (
            SELECT operating_system_category_id
            FROM operating_system_category
            WHERE NEW.operating_system_category_string REGEXP CONCAT('^', escape_regex_special_chars(operating_system_category), '$')
        );
    END IF;
END$$

-- Trigger to set operating_system_id in operating_system_instance before INSERT
CREATE TRIGGER trg_set_os_id_from_string_in_instance_insert
BEFORE INSERT ON operating_system_instance
FOR EACH ROW
BEGIN
    IF NEW.operating_system_string IS NOT NULL THEN
        SET NEW.operating_system_id = (
            SELECT operating_system_id
            FROM operating_system
            WHERE NEW.operating_system_string REGEXP CONCAT('^', escape_regex_special_chars(operating_system), '$')
        );
    END IF;
END$$

-- Trigger to set operating_system_id in operating_system_instance before UPDATE
CREATE TRIGGER trg_set_os_id_from_string_in_instance_update
BEFORE UPDATE ON operating_system_instance
FOR EACH ROW
BEGIN
    IF NEW.operating_system_string IS NOT NULL THEN
        SET NEW.operating_system_id = (
            SELECT operating_system_id
            FROM operating_system
            WHERE NEW.operating_system_string REGEXP CONCAT('^', escape_regex_special_chars(operating_system), '$')
        );
    END IF;
END$$

-- Trigger to set virtualization_software_id from string in virtualization_software_instance before INSERT
CREATE TRIGGER trg_set_virtualization_software_id_from_string_insert
BEFORE INSERT ON virtualization_software_instance
FOR EACH ROW
BEGIN
    IF NEW.virtualization_software_string IS NOT NULL THEN
        SET NEW.virtualization_software_id = (
            SELECT virtualization_software_id
            FROM virtualization_software
            WHERE NEW.virtualization_software_string REGEXP CONCAT('^', escape_regex_special_chars(virtualization_software), '$')
        );
    END IF;
END$$

-- Trigger to set virtualization_software_id from string in virtualization_software_instance before UPDATE
CREATE TRIGGER trg_set_virtualization_software_id_from_string_update
BEFORE UPDATE ON virtualization_software_instance
FOR EACH ROW
BEGIN
    IF NEW.virtualization_software_string IS NOT NULL THEN
        SET NEW.virtualization_software_id = (
            SELECT virtualization_software_id
            FROM virtualization_software
            WHERE NEW.virtualization_software_string REGEXP CONCAT('^', escape_regex_special_chars(virtualization_software), '$')
        );
    END IF;
END$$

-- Trigger to set virtualization_software_instance_id from string in virtual_machine before INSERT
CREATE TRIGGER trg_set_virtualization_software_instance_id_from_string_insert
BEFORE INSERT ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.virtualization_software_instance_string IS NOT NULL THEN
        SET NEW.virtualization_software_instance_id = (
            SELECT virtualization_software_instance_id
            FROM virtualization_software_instance
            WHERE NEW.virtualization_software_instance_string REGEXP CONCAT('^', escape_regex_special_chars(version), '$')
        );
    END IF;
END$$

-- Trigger to set virtualization_software_instance_id from string in virtual_machine before UPDATE
CREATE TRIGGER trg_set_virtualization_software_instance_id_from_string_update
BEFORE UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    IF NEW.virtualization_software_instance_string IS NOT NULL THEN
        SET NEW.virtualization_software_instance_id = (
            SELECT virtualization_software_instance_id
            FROM virtualization_software_instance
            WHERE NEW.virtualization_software_instance_string REGEXP CONCAT('^', escape_regex_special_chars(version), '$')
        );
    END IF;
END$$

-- Trigger to prevent both full_clone and linked_clone being set (either string or ID) before INSERT
CREATE TRIGGER trg_no_full_and_linked_clones_insert
BEFORE INSERT ON virtual_machine
FOR EACH ROW
BEGIN
    -- Prevent both full_clone and linked_clone being set (strings)
    IF (NEW.full_clone_parent_string IS NOT NULL AND NEW.linked_clone_parent_string IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both full_clone_parent_string and linked_clone_parent_string cannot be set.';
    END IF;

    -- Prevent both full_clone and linked_clone being set (IDs)
    IF (NEW.full_clone_parent_id IS NOT NULL AND NEW.linked_clone_parent_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both full_clone_parent_id and linked_clone_parent_id cannot be set.';
    END IF;

    -- Prevent full_clone_parent_string and linked_clone_parent_id being set
    IF (NEW.full_clone_parent_string IS NOT NULL AND NEW.linked_clone_parent_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_clone_parent_string and linked_clone_parent_id cannot both be set.';
    END IF;

    -- Prevent full_clone_parent_id and linked_clone_parent_string being set
    IF (NEW.full_clone_parent_id IS NOT NULL AND NEW.linked_clone_parent_string IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_clone_parent_id and linked_clone_parent_string cannot both be set.';
    END IF;
END$$

-- Trigger to prevent both full_clone and linked_clone being set (either string or ID) before UPDATE
CREATE TRIGGER trg_no_full_and_linked_clones_update
BEFORE UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    -- Prevent both full_clone and linked_clone being set (strings)
    IF (NEW.full_clone_parent_string IS NOT NULL AND NEW.linked_clone_parent_string IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both full_clone_parent_string and linked_clone_parent_string cannot be set.';
    END IF;

    -- Prevent both full_clone and linked_clone being set (IDs)
    IF (NEW.full_clone_parent_id IS NOT NULL AND NEW.linked_clone_parent_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both full_clone_parent_id and linked_clone_parent_id cannot be set.';
    END IF;

    -- Prevent full_clone_parent_string and linked_clone_parent_id being set
    IF (NEW.full_clone_parent_string IS NOT NULL AND NEW.linked_clone_parent_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_clone_parent_string and linked_clone_parent_id cannot both be set.';
    END IF;

    -- Prevent full_clone_parent_id and linked_clone_parent_string being set
    IF (NEW.full_clone_parent_id IS NOT NULL AND NEW.linked_clone_parent_string IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_clone_parent
_id and linked_clone_parent_string cannot both be set.';
END IF;
END$$

DELIMITER ;