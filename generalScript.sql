USE airlinecompanyschema;

/*TRIGGERs*/
DELIMITER $$
CREATE TRIGGER Seat_Insert
	AFTER INSERT
    ON airlinecompanyschema.seats
    FOR EACH ROW
BEGIN
    SET @newseatnum = NEW.flightSchedule_idflightSchedule;
    IF  NEW.seatType = 'E' THEN
		UPDATE airlinecompanyschema.flightschedule SET availableEcoSeats = availableEcoSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    ELSE 
		UPDATE airlinecompanyschema.flightschedule SET availBusiSeats = availBusiSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    END IF;
END;
$$

DELIMITER $$
CREATE TRIGGER Seat_Update
	AFTER UPDATE
    ON airlinecompanyschema.seats
    FOR EACH ROW
BEGIN
	SET @newseatnum = NEW.flightSchedule_idflightSchedule;
    IF NEW.seatType = 'E' THEN
        UPDATE airlinecompanyschema.flightschedule 
        SET    availableEcoSeats = availableEcoSeats - 1,
               availBusiSeats = availBusiSeats +1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
	ELSE
        UPDATE airlinecompanyschema.flightschedule 
        SET    availableEcoSeats = availableEcoSeats + 1, 
			   availBusiSeats = availBusiSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    END IF;
END;
$$

/*USER DEFINED FUNCTIONS*/
DELIMITER $
CREATE FUNCTION business_class_cost(flightid int,multiplier double)
RETURNS DOUBLE 
DETERMINISTIC
BEGIN
    DECLARE businessclassprize double;
    SELECT (fareEco*multiplier) INTO businessclassprize FROM flightschedule
    WHERE idflightSchedule = flightid;
    RETURN businessclassprize;
END;
$

DELIMITER $
CREATE FUNCTION flights_on_schedule()
RETURNS INT 
DETERMINISTIC
BEGIN
    DECLARE scheduledflights int;
    SELECT COUNT(idflightSchedule) INTO scheduledflights FROM flightschedule
    WHERE BookingInformation_Status_idStatus = 1;
    RETURN scheduledflights;
END;
$

/*VIEWS*/
CREATE VIEW CustomerBill AS
SELECT customer.firstName, flightschedule.idflightSchedule, route.departureAirport, route.arrivalAirport, flightschedule.fareEco, discounts.amount AS discountedPercent, charges.amount AS chargedAmount, (flightschedule.fareEco + charges.amount - ((discounts.amount/100)*flightschedule.fareEco)) AS TotalBill
FROM bookinginformation AS B
JOIN flightschedule ON idBookingInformation = flightschedule.BookingInformation_idBookingInformation
JOIN charges ON B.Charges_idCharges = charges.idCharges
JOIN discounts ON B.Discounts_iddissounts = discounts.iddissounts
JOIN customer ON customer.idCustomer = B.Customer_idCustomer
JOIN route ON flightschedule.Route_idRoute = route.idRoute;

/*STORED PROCEDURE*/
DELIMITER $
CREATE PROCEDURE SearchFlight(IN routeNumber INT)
BEGIN
	SELECT f.idflightSchedule, r.departureAirport, r.arrivalAirport, f.departureDate, f.departureTime, f.arrivalDate, f.arrivalTime, f.fareEco
    FROM flightschedule AS f
	INNER JOIN route AS r ON f.Route_idRoute = r.idRoute
    WHERE idRoute = routeNumber
    ORDER BY fareEco;
END;
$


/*USER PRIVILEGES*/
CREATE USER 'customer1'@localhost identified by 'customer1';
GRANT SELECT ON CustomerBill to 'customer1'@localhost;
GRANT SELECT ON flightschedule to 'customer1'@localhost;

CREATE USER 'airlineemployee'@localhost identified by 'airlineemployee';
GRANT SELECT ON customer to 'airlineemployee'@localhost;
GRANT SELECT ON flightschedule to 'airlineemployee'@localhost;
GRANT SELECT ON bookinginformation to 'airlineemployee'@localhost;

/*INDEXING*/
CREATE INDEX fare_index ON flightschedule(fareEco) USING BTREE;
CREATE INDEX discount_index ON discounts(amount) USING BTREE;
CREATE INDEX charges_index ON charges(amount) USING BTREE;

