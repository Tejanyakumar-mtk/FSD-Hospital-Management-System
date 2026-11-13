-- ============================================================================
-- Hospital Management System (HMS)
-- Database: Oracle 10g / 11g / 12c / 19c / 21c Compatible
-- Script 00: Destructive Database Teardown / Reset Script
-- CAUTION: RUN ONLY IF YOU WISH TO COMPLETELY DROP ALL HMS TABLES & SEQUENCES.
-- ============================================================================

BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'AUDIT_LOG', 'PAYMENTS', 'BILL_ITEMS', 'BILLS',
        'PRESCRIPTION_ITEMS', 'PRESCRIPTIONS', 'APPOINTMENTS',
        'DOCTOR_AVAILABILITY', 'USERS', 'PATIENTS', 'DOCTORS', 'DEPARTMENTS'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;

    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
        'SEQ_DEPARTMENTS', 'SEQ_DOCTORS', 'SEQ_PATIENTS', 'SEQ_USERS',
        'SEQ_DOCTOR_AVAILABILITY', 'SEQ_APPOINTMENTS', 'SEQ_PRESCRIPTIONS',
        'SEQ_PRESCRIPTION_ITEMS', 'SEQ_BILLS', 'SEQ_BILL_ITEMS',
        'SEQ_PAYMENTS', 'SEQ_AUDIT_LOG'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/
