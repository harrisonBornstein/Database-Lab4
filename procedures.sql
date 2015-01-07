 
 /*a. Create a procedure that creates a reservation on a specific flight. 
 (For the moment you do not need to check whether there are enough unpaid seats on the flight). */
DELIMITER //
CREATE PROCEDURE createReservation(IN flight INT(8))
BEGIN
    INSERT INTO RESERVATION (flight) VALUES (flight);
END//
DELIMITER ;


/*b. Create a procedure/procedures that adds passenger details (social security number, first name, surname)
 as well as contact information to a reservation.*/
DELIMITER //
CREATE PROCEDURE addPDetails(IN reservation INT(8),IN ssn INT(10), IN fname VARCHAR(25), IN lname VARCHAR(25), IN email VARCHAR(60), phoneNumber VARCHAR(15))
BEGIN
    INSERT INTO PASSENGER (id,FName,LName) VALUES (ssn,fname,lname);
    INSERT INTO PGROUP (passenger, reservation) VALUES (ssn, reservation);
    IF email IS NOT NULL THEN
        INSERT INTO CUSTOMER (passengerID,email,phoneNumber) VALUES (ssn,emailphoneNumber);
        UPDATE RESERVATION 
        SET customer = ssn
        WHERE id = reservation;
    END IF; 
END//
DELIMITER ;

/*c. Create a procedure that adds payment details such as the name on credit card, the credit card type, 
the expiry month, the expiry year, the credit card number and the amount drawn from the credit card account.*/ 
DELIMITER //
CREATE PROCEDURE register_card(cc_name VARCHAR, cc_type VARCHAR, cc_exp_m INT, cc_exp_y INT, cc_num INT, cc_amount FLOAT)
BEGIN
    INSERT INTO CCHOLDER (name, type, expMonth, expYear, ccNumber, amount)
    VALUES (cc_name, cc_type, cc_exp_m, cc_exp_y, cc_num, cc_amount);
END //
/*How can you protect the credit card information in the database from hackers? 
You do not need to implement this protection.

    We could protect the credit card information using one way functions such as hashing functions that would encrypt the data
    without allowing to decrypt it.*/

/*d. Create a trigger that automatically issues unique ticket numbers to each passenger in a reservation 
as soon as a payment for that reservation has been received. 
You may use a mathematical formula based on for example the reservation number to calculate the ticket number(s). 
The actual payment transaction takes place in the database of the credit card company and need not be considered here.*/
DELIMITER //
CREATE TRIGGER issue_booking AFTER UPDATE ON RESERVATION
FOR EACH ROW
BEGIN
    IF NOT (NEW.ccholder <=> OLD.ccholder) THEN
            INSERT INTO BOOKING (reservation,finalPrice) VALUES (NEW.id, (SELECT amount FROM CCHOLDER WHERE id = NEW.ccholder));
    END IF;
END//    
DELIMITER ;
            
/*e. Give three reasons why it is better to do the processing in stored procedures in the data-base 
compared of doing them in a java-script on the web-page in the front-end of the system?

    Doing the processing in stored procedures directly in the Database is better than doing it on the front-end because :
    - It saves bandwidth and avoids transferring too much data through the network, which is quite unreliable.
    - It offers better performances. A stored procedure is precompiled and already known by the Database ; 
    contrary to a request that would be made on the front end and then passed to the Database.
    - It ensures consistency of the database. These procedures are business requirements, they reflect the logic of the business
    and thus are independent of any other implementation. As such, it appears logical that the processing of data should be made
    within the database itself and not depend on one or several other interfaces. 
    For example if a BrianAir employee uses a specific software to book reservations 
    and an average customer can also make reservations through the BrianAir website, 
    there would be two different codes to make the same processing of data. 
    Whereas using stored procedures does it in only one place, making this easier and less prone to errors. */                
