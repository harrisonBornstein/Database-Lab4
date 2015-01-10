 
 /*a. Create a procedure that creates a reservation on a specific flight. 
 (For the moment you do not need to check whether there are enough unpaid seats on the flight). */
DROP PROCEDURE IF EXISTS createReservation; 
DELIMITER //
CREATE PROCEDURE createReservation(IN _flight INT(8))
BEGIN 
    IF (((SELECT fdate FROM FLIGHT where id = _flight) < DATE_ADD(CURDATE(),INTERVAL 1 YEAR)) AND count_open_seats(_flight) > 0 ) THEN 
        INSERT INTO RESERVATION (flight) VALUES (_flight);
    END IF;
END//
DELIMITER ;


/*b. Create a procedure/procedures that adds passenger details (social security number, first name, surname)
 as well as contact information to a reservation.*/
DROP PROCEDURE IF EXISTS addPDetails;
DELIMITER //
CREATE PROCEDURE addPDetails(IN reservation INT(8),IN ssn INT(10), IN fname VARCHAR(25), IN lname VARCHAR(25))
BEGIN
    DECLARE open_seats INT;
    DECLARE flight INT;
    SET flight = (SELECT flight FROM RESERVATION WHERE id = reservation);
    SET open_seats = (SELECT (count_open_seats(flight)));
    IF (open_seats > 0) THEN
        INSERT INTO PASSENGER (id,FName,LName) VALUES (ssn,fname,lname);
        INSERT INTO PGROUP (passenger, reservation) VALUES (ssn, reservation);
    END IF;    
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS addContact;
DELIMITER //
CREATE PROCEDURE addContact(IN reservation INT(8), IN email VARCHAR(60), IN _phoneNumber VARCHAR(15),IN ssn INT(10))
BEGIN
    IF (email IS NOT NULL AND _phoneNumber IS NOT NULL) THEN
        INSERT INTO CONTACT (passengerID,email,phoneNumber) VALUES (ssn,email,_phoneNumber);
        UPDATE RESERVATION SET contact = ssn WHERE id = reservation;
    END IF;
END// 
DELIMITER ;       

/*c. Create a procedure that adds payment details such as the name on credit card, the credit card type, 
the expiry month, the expiry year, the credit card number and the amount drawn from the credit card account.*/
DROP PROCEDURE IF EXISTS register_card; 
DELIMITER //
CREATE PROCEDURE register_card (IN cc_name VARCHAR(50),IN cc_type VARCHAR(25),IN cc_exp_m INT,IN cc_exp_y INT,IN cc_num INT,IN resID INT(8))
BEGIN
    DECLARE test1 INT;
    DECLARE numPass INT;
    DECLARE test3 INT;
    DECLARE flightID INT;
    DECLARE price FLOAT;
    SET flightID := (SELECT flight FROM RESERVATION WHERE id = resID);
    SET test1 := (SELECT IF(contact IS NULL,NULL,contact) AS contact FROM RESERVATION WHERE id =resID); 
    SET numPass := (SELECT COUNT(passenger) FROM PGROUP WHERE reservation=resID); 
    SET test3 := (SELECT openSeats FROM FLIGHT WHERE  id = flightID); 
    IF(test1 IS NOT NULL AND numPass > 0 AND test3 >= numPass) THEN
        SET price := (SELECT calc_price(flightID, (SELECT fdate FROM FLIGHT WHERE id = flightID),numPass));
        INSERT INTO CCHOLDER (name, type, expMonth, expYear, ccNumber, amount)
        VALUES (cc_name, cc_type, cc_exp_m, cc_exp_y, cc_num, price);
        UPDATE RESERVATION SET ccholder = (SELECT id FROM CCHOLDER WHERE name = cc_name) WHERE id = resID;
    END IF;   
END//
DELIMITER ;



/*How can you protect the credit card information in the database from hackers? 
You do not need to implement this protection.

    We could protect the credit card information using one way functions such as hashing functions that would encrypt the data
    without allowing to decrypt it.*/

/*d. Create a trigger that automatically issues unique ticket numbers to each passenger in a reservation 
as soon as a payment for that reservation has been received. 
You may use a mathematical formula based on for example the reservation number to calculate the ticket number(s). 
The actual payment transaction takes place in the database of the credit card company and need not be considered here.*/
DROP TRIGGER IF EXISTS issue_booking;
DELIMITER //
CREATE TRIGGER issue_booking AFTER UPDATE ON RESERVATION
FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE pReservation INT;
    DECLARE pID INT;
    DECLARE ticket TEXT;
    DECLARE cur CURSOR FOR SELECT reservation,passenger FROM PGROUP;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    IF NOT (NEW.ccholder <=> OLD.ccholder) THEN
            INSERT INTO BOOKING (reservation,finalPrice) VALUES (NEW.id, (SELECT amount FROM CCHOLDER WHERE id = NEW.ccholder));
            UPDATE FLIGHT SET openSeats = openSeats - (SELECT count(passenger) FROM PGROUP WHERE PGROUP.reservation = NEW.id) WHERE id = (SELECT flight FROM RESERVATION WHERE id = NEW.id);
            OPEN cur;
            read_loop: LOOP 
            FETCH cur INTO pReservation,pID;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                IF (pReservation <=> NEW.id) THEN
                    SET ticket = CONCAT (pReservation,pID);
                    INSERT INTO TRAVELLER (ticketNumber,passenger,booking) VALUES (ticket,pID,NEW.id);
                END IF;
            END LOOP;
            CLOSE cur;
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
    and an average contact can also make reservations through the BrianAir website, 
    there would be two different codes to make the same processing of data. 
    Whereas using stored procedures does it in only one place, making this easier and less prone to errors. */   




    /*6. In the above scenario we do not take the number of unpaid seats into account. Given a flight, and a date (if necessary), 
create a function that shows the number of available seats according to the reservation strategy (i.e. only payed seats are considered as booked, see. 1.i).
Add this function to the functions where it should be used as a check in order to allow the contact to proceed to the next step. Since the number of open
seats is stored in the database this function is not that usefull to us besides the fact it allows us to check and make sure the stored open seat number is correct*/
DROP FUNCTION IF EXISTS count_open_seats;
DELIMITER //
CREATE FUNCTION count_open_seats(paramFlight INT)
    RETURNS INT
BEGIN
    DECLARE taken_seats INT;
    SET taken_seats = (SELECT COUNT(passenger) FROM PGROUP WHERE PGROUP.reservation IN
                        (SELECT B.reservation FROM BOOKING B WHERE B.reservation IN 
                        (SELECT R.id FROM RESERVATION R WHERE R.flight = paramFlight)));
    RETURN  60 - taken_seats;
END//
DELIMITER ; 

-- LOOK AT SECTION I
-- UPDATE WEEKY FLIGHT on ER


DROP FUNCTION IF EXISTS calc_price;
DELIMITER //
CREATE FUNCTION calc_price (paramFlight INT, paramDate DATE, numPassengers INT) 
    RETURNS INT
BEGIN
    DECLARE final_price FLOAT;
    DECLARE _airportDest INT;
    DECLARE _airportDep INT;
    DECLARE weekDayFactor FLOAT;
    DECLARE booked_seats INT;
    SET booked_seats = 60 - (SELECT openSeats FROM FLIGHT WHERE id = paramFlight);
    SELECT airportDest,airportDep INTO _airportDest,_airportDep FROM WEEKLYFLIGHT WHERE id = (SELECT weeklyflight FROM FLIGHT WHERE id = paramFlight);
    SET weekDayFactor = (SELECT priceFactor FROM WEEKDAY WHERE (day = (SELECT id FROM DAY WHERE name = DAYNAME(paramDate)) AND year = YEAR(paramDate)));
    SET final_price = (SELECT price FROM ROUTE WHERE (airportDest = _airportDest AND airportDep = _airportDep)) * weekDayFactor * (booked_seats+numPassengers)/60 * (SELECT passengerFactor FROM YEAR WHERE year = YEAR(paramDate));
    RETURN final_price;
END//
DELIMITER ; 

--ASK ABOUT numPassengers
--ADD PASSENGERS TO RESERVATION?

DROP PROCEDURE IF EXISTS search_available_flights; 
DELIMITER //
CREATE PROCEDURE search_available_flights (IN airportDep VARCHAR(25),IN airportDest VARCHAR(25),IN numPassengers INT,IN _date DATE)
BEGIN
    DECLARE _airportDest INT;
    DECLARE _airportDep INT;
    DECLARE _flightID INT;
    SET _airportDep  = (SELECT id FROM AIRPORT WHERE name = airportDep);
    SET _airportDest = (SELECT id FROM AIRPORT WHERE name = airportDest);
    SELECT FLIGHT.fdate, FLIGHT.openSeats, WEEKLYFLIGHT.depTime, (SELECT calc_price(FLIGHT.id, FLIGHT.fdate,numPassengers)) AS Price FROM FLIGHT LEFT JOIN WEEKLYFLIGHT  
    ON FLIGHT.weeklyflight = WEEKLYFLIGHT.id
    WHERE (WEEKLYFLIGHT.airportDep = _airportDep AND WEEKLYFLIGHT.airportDest = _airportDest AND FLIGHT.openSeats >= numPassengers AND FLIGHT.fdate = _date);
END//
DELIMITER ; 

--For the first case if you assume it is correct then after you START TRANSACTION; you would commit it to the database with the command commit; For the second case you instead of COMMIT; you would call ROLLBACK;
    
START TRANSACTION;
LOCK TABLES RESERVATION WRITE,BOOKING WRITE,FLIGHT WRITE,TRAVELLER WRITE,PGROUP READ,YEAR READ,ROUTE READ,WEEKLYFLIGHT READ,DAY READ,WEEKDAY READ;
CALL register_card ('Carl','Visa',5,2016,8495830595839574,2);
UNLOCK TABLES;
COMMIT;

START TRANSACTION;
LOCK TABLES BOOKING WRITE,FLIGHT WRITE,RESERVATION WRITE;
UPDATE RESERVATION SET CCHOLDER=2 WHERE id=2;
UNLOCK TABLES;
COMMIT;

--Creating and Booking an open flight

mysql> CALL createReservation(2);
Query OK, 1 row affected (0.00 sec)

mysql> CALL addPDetails(3,10041993,'George','Smith');
Query OK, 1 row affected (0.01 sec)

mysql> CALL addContact(3,'george12@email.com','9723175555',10041993);
Query OK, 1 row affected (0.01 sec)

CALL register_card ('George','Visa',5,2016,8495830595839574,3); --This registers the card, charges the correct amount and books the flight.
Query OK, 1 row affected, 1 warning (0.01 sec)

--Trying to make a reservation when flight is full
mysql> CALL createReservation(2);
Query OK, 0 row affected (0.00 sec)

--Trying to make a booking (pay for flight) when flight is full
CALL register_card ('Joe','Visa',3,2016,8495839995839574,4); --This registers the card, charges the correct amount and books the flight.
Query OK, 0 row affected, 0 warning (0.01 sec)

--Search with search function
CALL search_available_flights('dub','lys',4,'2015-08-27');
+------------+-----------+----------+-------+
| fdate      | openSeats | depTime  | Price |
+------------+-----------+----------+-------+
| 2015-08-27 |        58 | 06:35:00 |    60 |
| 2015-08-27 |        60 | 17:30:00 |    40 |
+------------+-----------+----------+-------+
2 rows in set (0.01 sec)

Query OK, 0 rows affected (0.01 sec)





             
