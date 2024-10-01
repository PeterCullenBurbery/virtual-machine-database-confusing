-- 1. Create the virtualization_software table
CREATE TABLE virtualization_software (
    virtualization_software_id RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    virtualization_software    VARCHAR2(1000) NOT NULL,
    company                    VARCHAR2(1000) NOT NULL,
    CONSTRAINT uq_software_company UNIQUE ( virtualization_software,
                                            company ),

    -- Additional columns for note and dates
    note                       VARCHAR2(4000),  -- General-purpose note field
    date_created               TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated               TIMESTAMP(9) WITH TIME ZONE,
        date_created_or_updated    TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS ( coalesce(date_updated, date_created) ) VIRTUAL
);
-- 2. Create the operating_system table with operating_system_category_id
CREATE TABLE operating_system (
    operating_system_id RAW(16) DEFAULT SYS_GUID() PRIMARY KEY,
    operating_system VARCHAR2(1000) NOT NULL,
    operating_system_category_string VARCHAR2(1000) NOT NULL,
    operating_system_category_id RAW(16),  -- New column for foreign key reference
    
    CONSTRAINT fk_os_category FOREIGN KEY (operating_system_category_id)
        REFERENCES operating_system_category (operating_system_category_id),
    CONSTRAINT uq_os_category UNIQUE (operating_system, operating_system_category_string),

    -- Additional columns for note and dates
    note VARCHAR2(4000),  -- General-purpose note field
    date_created TIMESTAMP(9) WITH TIME ZONE DEFAULT SYSTIMESTAMP(9) NOT NULL,
    date_updated TIMESTAMP(9) WITH TIME ZONE,
    date_created_or_updated TIMESTAMP(9) WITH TIME ZONE 
        GENERATED ALWAYS AS (COALESCE(date_updated, date_created)) VIRTUAL
);


-- 3. Create the operating_system_category table
CREATE TABLE operating_system_category (
    operating_system_category_id RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    operating_system_category    VARCHAR2(1000) NOT NULL,
    description                  VARCHAR2(4000),
    CONSTRAINT uq_category UNIQUE ( operating_system_category ),

    -- Additional columns for note and dates
    note                         VARCHAR2(4000),  -- General-purpose note field
    date_created                 TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated                 TIMESTAMP(9) WITH TIME ZONE,
        date_created_or_updated      TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS ( coalesce(date_updated, date_created) ) VIRTUAL
);

-- 4. Create the operating_system_category_to_operating_system joining table
CREATE TABLE operating_system_category_to_operating_system (
    mapping_id                   RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    operating_system_id          RAW(16) NOT NULL,
    operating_system_category_id RAW(16) NOT NULL,
    CONSTRAINT fk_operating_system FOREIGN KEY ( operating_system_id )
        REFERENCES operating_system ( operating_system_id ),
    CONSTRAINT fk_operating_system_category FOREIGN KEY ( operating_system_category_id )
        REFERENCES operating_system_category ( operating_system_category_id ),
    CONSTRAINT uq_os_category_mapping UNIQUE ( operating_system_id,
                                               operating_system_category_id ),

    -- Additional columns for note and dates
    note                         VARCHAR2(4000),  -- General-purpose note field
    date_created                 TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated                 TIMESTAMP(9) WITH TIME ZONE,
        date_created_or_updated      TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS ( coalesce(date_updated, date_created) ) VIRTUAL
);

-- Modify the operating_system_instance table to include operating_system_id
CREATE TABLE operating_system_instance (
    operating_system_instance_id RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    operating_system_instance_string VARCHAR2(2001) GENERATED ALWAYS AS (operating_system_string || ' ' || version) VIRTUAL,
    
    operating_system_string VARCHAR2(1000) NOT NULL,  -- String for operating system    
    version VARCHAR2(1000) NOT NULL,  -- Version of the operating system
operating_system_id RAW(16),  -- Foreign key reference to operating_system
    -- Foreign key constraint
    CONSTRAINT fk_operating_system FOREIGN KEY (operating_system_id)
        REFERENCES operating_system (operating_system_id),

    -- Additional columns
    note VARCHAR2(4000),  -- General-purpose note field
    date_created TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated TIMESTAMP(9) WITH TIME ZONE,
    date_created_or_updated TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS (coalesce(date_updated, date_created)) VIRTUAL
);



-- Create the virtualization_software_instance table linked to virtualization_software
CREATE TABLE virtualization_software_instance (
    virtualization_software_instance_id RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    virtualization_software_string      VARCHAR2(4000) NOT NULL,  -- String for virtualization software
    virtualization_software_id          RAW(16) NOT NULL,         -- Foreign key to virtualization_software
    version                             VARCHAR2(1000) NOT NULL,  -- Version of the virtualization software

    CONSTRAINT fk_virtualization_software_for_virtualization_software_instance FOREIGN KEY (virtualization_software_id)
        REFERENCES virtualization_software (virtualization_software_id),

    -- Additional columns for note and dates
    note                                VARCHAR2(4000),  -- General-purpose note field
    date_created                        TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated                        TIMESTAMP(9) WITH TIME ZONE,
    date_created_or_updated             TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS ( coalesce(date_updated, date_created) ) VIRTUAL
);


-- 6. Create the virtual_machine table with links to operating_system_instance
CREATE TABLE virtual_machine (
    virtual_machine_id                        RAW(16) DEFAULT sys_guid() PRIMARY KEY,
    machine_name                              VARCHAR2(4000) NOT NULL,
    short_description                         VARCHAR2(4000),
    description                               VARCHAR2(4000),
virtualization_software_instance_string   VARCHAR2(4000) NOT NULL, -- String for virtualization software instance
    virtualization_software_instance_id       RAW(16) NOT NULL,
    operating_system_instance_string          VARCHAR2(4000) NOT NULL,
    operating_system_instance_id              RAW(16) NOT NULL,

    -- New columns for cloning
    full_clone_parent_string                  VARCHAR2(4000),
    full_clone_parent_id                      RAW(16),
    linked_clone_parent_string                VARCHAR2(4000),
    linked_clone_parent_id                    RAW(16),

    -- Allowing larger values for RAM, processors, and disk size
    ram                                       NUMBER(20, 0) NOT NULL,  -- RAM is in bytes
    number_of_processors                      NUMBER(4, 0) NOT NULL,  -- Allows up to 1000 processors
    cores_per_processor                       NUMBER(4, 0) NOT NULL,  -- Allows up to 1000 cores per processor
        total_processor_cores AS ( number_of_processors * cores_per_processor ) VIRTUAL,  -- Virtual column to calculate total processors
    disk_size                                 NUMBER(20, 0) NOT NULL,  -- Disk size is in bytes

    nested_virtualization_enabled             NUMBER(1) DEFAULT 0 NOT NULL CHECK ( nested_virtualization_enabled IN ( 0, 1 ) ),
    iso_image_file                            VARCHAR2(4000),
    network_drives_enabled_and_used           NUMBER(1) DEFAULT 0 NOT NULL CHECK ( network_drives_enabled_and_used IN ( 0, 1 ) ),
    hard_disk_file                            VARCHAR2(4000),
    shared_clipboard_is_working_and_turned_on NUMBER(1) DEFAULT 1 NOT NULL CHECK ( shared_clipboard_is_working_and_turned_on IN ( 0, 1) ),

    -- Additional columns for note and dates
    note                                      VARCHAR2(4000),  -- General-purpose note field
    date_created                              TIMESTAMP(9) WITH TIME ZONE DEFAULT systimestamp(9) NOT NULL,
    date_updated                              TIMESTAMP(9) WITH TIME ZONE,
        date_created_or_updated                   TIMESTAMP(9) WITH TIME ZONE GENERATED ALWAYS AS ( coalesce(date_updated, date_created
        ) ) VIRTUAL,

    -- Foreign key constraints
    CONSTRAINT fk_virtualization_software_for_vm FOREIGN KEY ( virtualization_software_instance_id )
        REFERENCES virtualization_software_instance ( virtualization_software_instance_id ),
    CONSTRAINT fk_operating_system_instance_for_vm FOREIGN KEY ( operating_system_instance_id )
        REFERENCES operating_system_instance ( operating_system_instance_id ),
    CONSTRAINT fk_full_clone_parent_for_vm FOREIGN KEY ( full_clone_parent_id )
        REFERENCES virtual_machine ( virtual_machine_id ),
    CONSTRAINT fk_linked_clone_parent_for_vm FOREIGN KEY ( linked_clone_parent_id )
        REFERENCES virtual_machine ( virtual_machine_id )
);


-- Add comments for RAM, disk size, processors, and cores per processor in virtual_machine
COMMENT ON COLUMN virtual_machine.ram IS
    'RAM is in bytes';

COMMENT ON COLUMN virtual_machine.disk_size IS
    'Disk size is in bytes';

COMMENT ON COLUMN virtual_machine.total_processors IS
    'Total processors calculated as number_of_processors * cores_per_processor';

COMMENT ON COLUMN virtual_machine.number_of_processors IS
    'Allows up to 1000 processors';

COMMENT ON COLUMN virtual_machine.cores_per_processor IS
    'Allows up to 1000 cores per processor';

-- Triggers to update date_updated

-- Trigger to update date_updated for virtualization_software
CREATE OR REPLACE TRIGGER trg_set_date_updated_virt_software BEFORE
    UPDATE ON virtualization_software
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update date_updated for operating_system
CREATE OR REPLACE TRIGGER trg_set_date_updated_os BEFORE
    UPDATE ON operating_system
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update date_updated for operating_system_category
CREATE OR REPLACE TRIGGER trg_set_date_updated_os_category BEFORE
    UPDATE ON operating_system_category
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update date_updated for operating_system_category_to_operating_system
CREATE OR REPLACE TRIGGER trg_set_date_updated_os_cat_to_os BEFORE
    UPDATE ON operating_system_category_to_operating_system
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update date_updated for operating_system_instance
CREATE OR REPLACE TRIGGER trg_set_date_updated_os_instance BEFORE
    UPDATE ON operating_system_instance
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update date_updated for virtual_machine
CREATE OR REPLACE TRIGGER trg_set_date_updated_vm BEFORE
    UPDATE ON virtual_machine
    FOR EACH ROW
BEGIN
    :new.date_updated := systimestamp;
END;
/

-- Trigger to update operating_system_instance_id from string in virtual_machine
CREATE OR REPLACE TRIGGER trg_set_operating_system_instance_id_from_string BEFORE
    INSERT OR UPDATE ON virtual_machine
    FOR EACH ROW
BEGIN
    IF :new.operating_system_instance_string IS NOT NULL THEN
        SELECT
            operating_system_instance_id
        INTO :new.operating_system_instance_id
        FROM
            operating_system_instance
        WHERE
            REGEXP_LIKE ( operating_system_instance_string,
                          '^'
                          || :new.operating_system_instance_string
                          || '$',
                          'i' );

    END IF;
END;
/



-- Trigger to update full_clone_parent_id from string in virtual_machine
CREATE OR REPLACE TRIGGER trg_set_full_clone_parent_id_from_string BEFORE
    INSERT OR UPDATE ON virtual_machine
    FOR EACH ROW
BEGIN
    IF :new.full_clone_parent_string IS NOT NULL THEN
        SELECT
            virtual_machine_id
        INTO :new.full_clone_parent_id
        FROM
            virtual_machine
        WHERE
            REGEXP_LIKE ( machine_name,
                          '^'
                          || :new.full_clone_parent_string
                          || '$',
                          'i' );

    END IF;
END;
/

-- Trigger to update linked_clone_parent_id from string in virtual_machine
CREATE OR REPLACE TRIGGER trg_set_linked_clone_parent_id_from_string BEFORE
    INSERT OR UPDATE ON virtual_machine
    FOR EACH ROW
BEGIN
    IF :new.linked_clone_parent_string IS NOT NULL THEN
        SELECT
            virtual_machine_id
        INTO :new.linked_clone_parent_id
        FROM
            virtual_machine
        WHERE
            REGEXP_LIKE ( machine_name,
                          '^'
                          || :new.linked_clone_parent_string
                          || '$',
                          'i' );

    END IF;
END;
/

-- Trigger to prevent both full_clone and linked_clone being set (either string or ID)
CREATE OR REPLACE TRIGGER trg_no_full_and_linked_clones BEFORE
    INSERT OR UPDATE ON virtual_machine
    FOR EACH ROW
BEGIN
-- Prevent both full_clone and linked_clone being set (strings)
    IF (
        :new.full_clone_parent_string IS NOT NULL
        AND :new.linked_clone_parent_string IS NOT NULL
    ) THEN
        raise_application_error(-20001, 'Both full_clone_parent_string and linked_clone_parent_string cannot be set.');
    END IF;

-- Prevent both full_clone and linked_clone being set (IDs)
    IF (
        :new.full_clone_parent_id IS NOT NULL
        AND :new.linked_clone_parent_id IS NOT NULL
    ) THEN
        raise_application_error(-20002, 'Both full_clone_parent_id and linked_clone_parent_id cannot be set.');
    END IF;

-- Prevent full_clone_parent_string and linked_clone_parent_id being set
    IF (
        :new.full_clone_parent_string IS NOT NULL
        AND :new.linked_clone_parent_id IS NOT NULL
    ) THEN
        raise_application_error(-20003, 'full_clone_parent_string and linked_clone_parent_id cannot both be set.');
    END IF;

-- Prevent full_clone_parent_id and linked_clone_parent_string being set
    IF (
        :new.full_clone_parent_id IS NOT NULL
        AND :new.linked_clone_parent_string IS NOT NULL
    ) THEN
        raise_application_error(-20004, 'full_clone_parent_id and linked_clone_parent_string cannot both be set.');
    END IF;

END;
/

-- Trigger to set operating_system_category_id based on operating_system_category_string
CREATE OR REPLACE TRIGGER trg_set_os_category_id_from_string
BEFORE INSERT OR UPDATE ON operating_system
FOR EACH ROW
BEGIN
    IF :NEW.operating_system_category_string IS NOT NULL THEN
        SELECT operating_system_category_id
        INTO :NEW.operating_system_category_id
        FROM operating_system_category
        WHERE REGEXP_LIKE(operating_system_category, '^' || :NEW.operating_system_category_string || '$', 'i');
    END IF;
END;
/

-- Trigger to set operating_system_id in operating_system_instance based on operating_system_string
CREATE OR REPLACE TRIGGER trg_set_os_id_from_string_in_instance
BEFORE INSERT OR UPDATE ON operating_system_instance
FOR EACH ROW
BEGIN
    IF :NEW.operating_system_string IS NOT NULL THEN
        SELECT operating_system_id
        INTO :NEW.operating_system_id
        FROM operating_system
        WHERE REGEXP_LIKE(operating_system, '^' || :NEW.operating_system_string || '$', 'i');
    END IF;
END;
/

-- Trigger to update virtualization_software_id based on virtualization_software_string in virtualization_software_instance
CREATE OR REPLACE TRIGGER trg_set_virtualization_software_id_from_string
BEFORE INSERT OR UPDATE ON virtualization_software_instance
FOR EACH ROW
BEGIN
    IF :NEW.virtualization_software_string IS NOT NULL THEN
        SELECT virtualization_software_id
        INTO :NEW.virtualization_software_id
        FROM virtualization_software
        WHERE REGEXP_LIKE(virtualization_software, '^' || :NEW.virtualization_software_string || '$', 'i');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER trg_set_virtualization_software_instance_id_from_string
BEFORE INSERT OR UPDATE ON virtual_machine
FOR EACH ROW
BEGIN
    IF :NEW.virtualization_software_instance_string IS NOT NULL THEN
        SELECT virtualization_software_instance_id
        INTO :NEW.virtualization_software_instance_id
        FROM virtualization_software_instance
        WHERE REGEXP_LIKE(version, '^' || :NEW.virtualization_software_instance_string || '$', 'i');
    END IF;
END;
/

-- Trigger to update date_updated for virtualization_software_instance
CREATE OR REPLACE TRIGGER trg_set_date_updated_for_virtualization_instance
BEFORE UPDATE ON virtualization_software_instance
FOR EACH ROW
BEGIN
    -- Set the date_updated to the current timestamp when a row is updated
    :NEW.date_updated := SYSTIMESTAMP;
END;
/
