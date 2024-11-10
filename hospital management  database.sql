create database hospital_management_system;
use hospital_management_system;

-- Hospital Management Database Schema Desgin --

-- Patient Table
create table patient (
    patient_id int unsigned auto_increment primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    phone_no varchar(20) not null,
    age int not null,
    visit_date date not null,
    health_issue varchar(100) not null
) engine=InnoDB;

-- Doctor Table
create table doctor (
    doctor_id int unsigned auto_increment primary key,
    full_name varchar(100) not null,
    email varchar(150) unique not null,
    phone_no varchar(20) unique not null,
    speciality varchar(50) not null,
    availability enum('available','not available') default 'available'
) engine=InnoDB;

-- Appointment Table
create table appointment (
    appointment_id int unsigned auto_increment primary key,
    patient_id int unsigned,
    doctor_id int unsigned,
    appointment_date datetime not null,
    status enum('Scheduled', 'Completed', 'Cancelled') default 'Scheduled',
    foreign key (patient_id) references patient(patient_id) on delete cascade,
    foreign key (doctor_id) references doctor(doctor_id) on delete cascade
) engine=InnoDB;

-- Room Table
create table room (
    room_id int unsigned auto_increment primary key,
    room_number varchar(20) unique not null,
    capacity int default 4,
    current_occupancy int default 0,
    is_available TINYINT(1) default 1
) engine=InnoDB;

-- Patient Room Assignment Table
create table patient_room (
    assign_id int unsigned auto_increment primary key,
    room_id int unsigned,
    patient_id int unsigned,
    assign_date datetime default current_timestamp,
    discharge_date datetime,
    foreign key (room_id) references room(room_id) on delete cascade,
    foreign key (patient_id) references patient(patient_id) on delete cascade
) engine=InnoDB;

-- Invoices Table
create table invoices (
    txn_id int unsigned not null unique primary key,
    assign_id int unsigned,
    room_charge decimal(12,2) default 0,
    doctor_charge decimal(12,2) default 0,
    medical_charge decimal(12,2) default 0,
    discount decimal(12,2) default 0,
    tax decimal(12,2) default 0,
    total_amount decimal(10,2) ,
    payable_amount decimal(10,2),
    foreign key (assign_id) references patient_room(assign_id) on delete cascade
) engine=InnoDB;

-- creating index for fast performance
CREATE INDEX idx_patient_phone_no ON patient(phone_no);
CREATE INDEX idx_doctor_speciality ON doctor(speciality);
CREATE INDEX idx_appointment_date ON appointment(appointment_date);
CREATE INDEX idx_appointment_status ON appointment(status);
CREATE INDEX idx_room_is_available ON room(is_available);
CREATE INDEX idx_invoices_assign_id ON invoices(assign_id);
CREATE INDEX idx_appointment_doctor_date ON appointment(doctor_id, appointment_date);

-- Stored Procedure for Patients Details--

DELIMITER $$
CREATE PROCEDURE GetPatientDetail(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_status varchar(20) 
)
BEGIN
    SELECT 
        patient.patient_id,
        CONCAT(patient.first_name, ' ', patient.last_name) AS Full_name,
        patient.health_issue,
        appointment.appointment_id,
        appointment.doctor_id,
        doctor.full_name AS doctor_name,
        appointment.appointment_date,
        appointment.status
    FROM 
        patient
    JOIN 
        appointment ON patient.patient_id = appointment.patient_id
    JOIN 
        doctor ON doctor.doctor_id = appointment.doctor_id
    WHERE 
        (p_patient_id IS NULL OR patient.patient_id = p_patient_id) AND
        (p_doctor_id IS NULL OR doctor.doctor_id = p_doctor_id) AND
        (p_status IS NULL OR appointment.status = p_status)
    ORDER BY 
        appointment.appointment_date;
END $$
DELIMITER ;

call GetPatientDetail(null,null,null);

-- Trigger Declaration -- for room bookings--

DELIMITER $$

CREATE TRIGGER after_patient_room_insert
AFTER INSERT ON patient_room
FOR EACH ROW
BEGIN
    DECLARE available_room_id INT;

    -- Check if the current room is full
    IF (SELECT current_occupancy FROM room WHERE room_id = NEW.room_id) >=
       (SELECT capacity FROM room WHERE room_id = NEW.room_id) THEN

        -- Find an available room with enough capacity
        SELECT room_id INTO available_room_id
        FROM room
        WHERE is_available = TRUE
          AND current_occupancy < capacity
        LIMIT 1;

        -- If an available room is found, update the patient assignment
        IF available_room_id IS NOT NULL THEN
            -- Update the patient_room assignment
            UPDATE patient_room
            SET room_id = available_room_id
            WHERE assign_id = NEW.assign_id;

            -- Update the current occupancy of the new room
            UPDATE room
            SET current_occupancy = current_occupancy + 1
            WHERE room_id = available_room_id;

            -- Set the original room as full if it has reached capacity
            UPDATE room
            SET is_available = FALSE
            WHERE room_id = NEW.room_id
              AND current_occupancy >= capacity;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available rooms for assignment.';
        END IF;
    ELSE
        -- Update the current occupancy of the assigned room
        UPDATE room
        SET current_occupancy = current_occupancy + 1
        WHERE room_id = NEW.room_id;
    END IF;
END $$
Delimiter ;

-- Trigger for generating invoices --

DELIMITER //

CREATE TRIGGER generate_invoice
BEFORE INSERT ON invoices
FOR EACH ROW
BEGIN
   DECLARE total_amount DECIMAL(10,2);
   DECLARE payable_amount DECIMAL(10,2);
   
   -- Calculate total_amount and payable_amount
   SET total_amount = NEW.room_charge + NEW.doctor_charge + NEW.medical_charge + NEW.tax;
   SET payable_amount = total_amount - NEW.discount;
   
   -- Set the calculated values to the new record
   SET NEW.total_amount = total_amount;
   SET NEW.payable_amount = payable_amount;
END //

DELIMITER ;
