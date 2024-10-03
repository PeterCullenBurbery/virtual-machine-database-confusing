CREATE DATABASE virtual_machine;
GO

USE virtual_machine;
GO

CREATE TABLE virtualization_software (
    virtualization_software_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    virtualization_software    VARCHAR(1000) NOT NULL,
    company                    VARCHAR(1000) NOT NULL,
    CONSTRAINT uq_software_company UNIQUE (virtualization_software, company),

    -- Additional columns for note and dates
    note                       VARCHAR(4000),  -- General-purpose note field
    date_created               DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated               DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE operating_system (
    operating_system_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    operating_system VARCHAR(1000) NOT NULL,
    operating_system_category_string VARCHAR(1000) NOT NULL,
    operating_system_category_id UNIQUEIDENTIFIER,  -- Foreign key reference
    
    CONSTRAINT fk_os_category FOREIGN KEY (operating_system_category_id)
        REFERENCES operating_system_category (operating_system_category_id),
    CONSTRAINT uq_os_category UNIQUE (operating_system, operating_system_category_string),

    -- Additional columns for note and dates
    note VARCHAR(4000),  -- General-purpose note field
    date_created DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE operating_system_category (
    operating_system_category_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    operating_system_category    VARCHAR(1000) NOT NULL,
    description                  VARCHAR(4000),
    CONSTRAINT uq_category UNIQUE (operating_system_category),

    -- Additional columns for note and dates
    note                         VARCHAR(4000),  -- General-purpose note field
    date_created                 DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated                 DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE operating_system_category_to_operating_system (
    mapping_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    operating_system_id UNIQUEIDENTIFIER NOT NULL,
    operating_system_category_id UNIQUEIDENTIFIER NOT NULL,
    
    CONSTRAINT fk_operating_system FOREIGN KEY (operating_system_id)
        REFERENCES operating_system (operating_system_id),
    CONSTRAINT fk_operating_system_category FOREIGN KEY (operating_system_category_id)
        REFERENCES operating_system_category (operating_system_category_id),
    CONSTRAINT uq_os_category_mapping UNIQUE (operating_system_id, operating_system_category_id),

    -- Additional columns for note and dates
    note                         VARCHAR(4000),  -- General-purpose note field
    date_created                 DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated                 DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE operating_system_instance (
    operating_system_instance_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    operating_system_string VARCHAR(1000) NOT NULL,
    version VARCHAR(1000) NOT NULL,  -- Version of the operating system
    operating_system_instance_string AS (operating_system_string + ' ' + version) PERSISTED,  -- Virtual column
    
    operating_system_id UNIQUEIDENTIFIER,  -- Foreign key reference to operating_system
    iso_image_file VARCHAR(4000),

    CONSTRAINT fk_operating_system FOREIGN KEY (operating_system_id)
        REFERENCES operating_system (operating_system_id),

    -- Additional columns for note and dates
    note VARCHAR(4000),  -- General-purpose note field
    date_created DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE virtualization_software_instance (
    virtualization_software_instance_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    virtualization_software_string      VARCHAR(4000) NOT NULL,  -- String for virtualization software
    virtualization_software_id UNIQUEIDENTIFIER NOT NULL,  -- Foreign key to virtualization_software
    version                             VARCHAR(1000) NOT NULL,  -- Version of the virtualization software

    CONSTRAINT fk_virtualization_software_for_virtualization_software_instance FOREIGN KEY (virtualization_software_id)
        REFERENCES virtualization_software (virtualization_software_id),

    -- Additional columns for note and dates
    note                                VARCHAR(4000),  -- General-purpose note field
    date_created                        DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated                        DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column
);

CREATE TABLE virtual_machine (
    virtual_machine_id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    machine_name VARCHAR(4000) NOT NULL,
    short_description VARCHAR(4000),
    description VARCHAR(4000),
    
    virtualization_software_instance_string VARCHAR(4000) NOT NULL,  -- String for virtualization software instance
    virtualization_software_instance_id UNIQUEIDENTIFIER NOT NULL,
    operating_system_instance_string VARCHAR(4000) NOT NULL,
    operating_system_instance_id UNIQUEIDENTIFIER NOT NULL,

    -- New columns for cloning
    full_clone_parent_string VARCHAR(4000),
    full_clone_parent_id UNIQUEIDENTIFIER,
    linked_clone_parent_string VARCHAR(4000),
    linked_clone_parent_id UNIQUEIDENTIFIER,

    -- Allowing larger values for RAM, processors, and disk size
    ram BIGINT NOT NULL,  -- RAM is in bytes
    number_of_processors INT NOT NULL,  -- Allows up to 1000 processors
    cores_per_processor INT NOT NULL,  -- Allows up to 1000 cores per processor
    total_processor_cores AS (number_of_processors * cores_per_processor) PERSISTED,  -- Virtual column
    disk_size BIGINT NOT NULL,  -- Disk size is in bytes

    nested_virtualization_enabled BIT DEFAULT 0 NOT NULL CHECK (nested_virtualization_enabled IN (0, 1)),
    network_drives_enabled_and_used BIT DEFAULT 0 CHECK (network_drives_enabled_and_used IN (0, 1)),
    hard_disk_file VARCHAR(4000),
    shared_clipboard_is_working_and_turned_on BIT DEFAULT 1 NOT NULL CHECK (shared_clipboard_is_working_and_turned_on IN (0, 1)),

    -- Additional columns for note and dates
    note VARCHAR(4000),  -- General-purpose note field
    date_created DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    date_updated DATETIME2 NULL,
    date_created_or_updated AS ISNULL(date_updated, date_created)  -- Virtual column,

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
