	
DELIMITER //
CREATE PROCEDURE createReservation(IN flight INT(8))
BEGIN
	INSERT INTO RESERVATION (flight) VALUES (flight);
END//
DELIMITER ;


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
	END IF	
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER issue_tickets
	AFTER UPDATE ON RESERVATION
	IF NOT (NEW.ccholder <=> OLD.ccholder) THEN
		FOR EACH ROW
			BEGIN
				INSERT INTO TRAVELLER (ticketNumber)
				SELECT id
					FROM RESERVATION
					WHERE RESERVATION.id =
				VALUES () 
				WHERE RESERVATION.id = (SELECT id FROM PGROUP)
