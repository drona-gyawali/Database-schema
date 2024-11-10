
---

# **Hospital Management System Database**

## **Overview**
This project is focused on designing the **Hospital Management System (HMS) database** using **MySQL**. The database schema is structured to efficiently store and manage data for patients, doctors, appointments, rooms, and invoices. It provides an optimized relational model for handling hospital operations, including patient information, doctor details, room assignments, appointment schedules, and billing.

## **Database Design**

The **Hospital Management System Database** consists of several interrelated tables that store different aspects of hospital operations:

### 1. **Patient Table**
Stores the personal and medical details of patients.

- `patient_id`: **INT**, Primary Key, Auto Increment
- `first_name`: **VARCHAR(50)**
- `last_name`: **VARCHAR(50)**
- `phone_no`: **VARCHAR(15)**
- `age`: **INT**
- `visit_date`: **DATE**
- `health_issue`: **TEXT**

### 2. **Doctor Table**
Stores information about doctors, including their specializations and contact details.

- `doctor_id`: **INT**, Primary Key, Auto Increment
- `full_name`: **VARCHAR(100)**
- `email`: **VARCHAR(100)**
- `phone_no`: **VARCHAR(15)**
- `speciality`: **VARCHAR(50)**
- `availability`: **ENUM('available', 'not available')**

### 3. **Appointment Table**
Keeps track of appointments between doctors and patients.

- `appointment_id`: **INT**, Primary Key, Auto Increment
- `patient_id`: **INT**, Foreign Key referencing `patient_id`
- `doctor_id`: **INT**, Foreign Key referencing `doctor_id`
- `appointment_date`: **DATETIME**
- `status`: **ENUM('Scheduled', 'Completed', 'Cancelled')**

### 4. **Room Table**
Manages room availability and occupancy for patients.

- `room_id`: **INT**, Primary Key, Auto Increment
- `room_number`: **VARCHAR(20)**
- `capacity`: **INT**
- `current_occupancy`: **INT**
- `is_available`: **BOOLEAN (1 for available, 0 for not available)**

### 5. **Patient Room Assignment Table**
Tracks which patient is assigned to which room.

- `assign_id`: **INT**, Primary Key, Auto Increment
- `room_id`: **INT**, Foreign Key referencing `room_id`
- `patient_id`: **INT**, Foreign Key referencing `patient_id`
- `assign_date`: **DATE**
- `discharge_date`: **DATE**

### 6. **Invoices Table**
Handles patient billing, including room charges, doctor fees, and medical charges.

- `txn_id`: **INT**, Primary Key, Auto Increment
- `assign_id`: **INT**, Foreign Key referencing `assign_id`
- `room_charge`: **DECIMAL(10,2)**
- `doctor_charge`: **DECIMAL(10,2)**
- `medical_charge`: **DECIMAL(10,2)**
- `discount`: **DECIMAL(10,2)**
- `tax`: **DECIMAL(10,2)**
- `total_amount`: **DECIMAL(10,2)**
- `payable_amount`: **DECIMAL(10,2)**

## **Relationships**
- **Patient ↔ Appointment**: One-to-many relationship (one patient can have multiple appointments).
- **Doctor ↔ Appointment**: One-to-many relationship (one doctor can have multiple appointments).
- **Patient ↔ Room Assignment**: One-to-many relationship (a patient can be assigned to multiple rooms during their stay).
- **Room ↔ Room Assignment**: One-to-many relationship (a room can be assigned to multiple patients over time).
- **Room Assignment ↔ Invoices**: One-to-one relationship (one room assignment corresponds to one invoice).

## **Stored Procedures**
Stored procedures help streamline the process of fetching data based on specific parameters and ensure better performance for frequently used queries.

For example, the **GetPatientDetail** procedure retrieves detailed patient information based on the patient ID, doctor ID, and appointment status.

```sql
DELIMITER $$

CREATE PROCEDURE GetPatientDetail(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_status VARCHAR(20)
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
```

## **Triggers**
Triggers automate specific actions when certain conditions are met.

- **After Insert Trigger**: Automatically assigns a new room to a patient when a new room assignment record is inserted. It ensures that rooms are available and have sufficient capacity.
- **Invoice Calculation Trigger**: Calculates the total and payable amounts after the insertion of a new invoice record.

## **Setup Instructions**

1. **Clone the Repository**:
   If the database script is hosted on GitHub:
   ```bash
   git clone https://github.com/your-username/hospital-management-system-db.git
   cd hospital-management-system-db
   ```

2. **Run the SQL Script**:
   Import the database schema into your MySQL database. Use MySQL Workbench or a CLI:
   ```sql
   source hospital_management_system.sql;
   ```

3. **Test the Database**:
   - Insert some test data into the tables (`patients`, `doctors`, `appointments`, etc.).
   - Call the stored procedures to check if everything works as expected.
   - Insert a few room assignments and invoices to test the triggers.

## **License**
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
