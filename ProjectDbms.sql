Create database ProjectDbms;

use ProjectDbms;

CREATE TABLE Hotel (
hotel_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
location VARCHAR(100) NOT NULL
);


CREATE TABLE Room (
room_id INT PRIMARY KEY AUTO_INCREMENT,
hotel_id INT NOT NULL,
room_no VARCHAR(10) NOT NULL,
type VARCHAR(20), -- e.g., Single, Double, Suite
price DECIMAL(8,2),
status ENUM('available','booked','maintenance') DEFAULT 'available',
FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);


CREATE TABLE Guest (
guest_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
phone VARCHAR(20),
email VARCHAR(100)
);


CREATE TABLE Booking (
booking_id INT PRIMARY KEY AUTO_INCREMENT,
guest_id INT NOT NULL,
room_id INT NOT NULL,
check_in DATE NOT NULL,
check_out DATE NOT NULL,
amount DECIMAL(10,2),
status ENUM('confirmed','checked_in','checked_out','cancelled') DEFAULT 'confirmed',
FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
FOREIGN KEY (room_id) REFERENCES Room(room_id)
);


CREATE TABLE Payment (
payment_id INT PRIMARY KEY AUTO_INCREMENT,
booking_id INT NOT NULL,
amount DECIMAL(10,2) NOT NULL,
payment_date DATE,
method VARCHAR(30),
FOREIGN KEY (booking_id) REFERENCES Booking(booking_id)
);


CREATE TABLE Staff (
staff_id INT PRIMARY KEY AUTO_INCREMENT,
hotel_id INT NOT NULL,
name VARCHAR(100),
role VARCHAR(50),
salary DECIMAL(10,2),
FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);



INSERT INTO Hotel (name, location) VALUES
('Sunrise Hotel','Bengaluru'),
('Ocean View','Goa');


INSERT INTO Room (hotel_id, room_no, type, price, status) VALUES
(1,'101','Single',1500.00,'available'),
(1,'102','Double',2500.00,'available'),
(1,'201','Suite',5000.00,'maintenance'),
(2,'101','Single',2000.00,'available'),
(2,'102','Double',3000.00,'booked');


INSERT INTO Guest (name, phone, email) VALUES
('Asha Rao','+919876543210','asha@example.com'),
('Ravi Kumar','+919812345678','ravi@example.com'),
('Maya Singh','+919900112233','maya@example.com');


INSERT INTO Booking (guest_id, room_id, check_in, check_out, amount, status) VALUES
(1,2,'2025-10-20','2025-10-22',5000.00,'confirmed'),
(2,5,'2025-11-01','2025-11-05',12000.00,'checked_in'),
(3,1,'2025-09-10','2025-09-12',3000.00,'checked_out');


INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES
(1,5000.00,'2025-10-19','Card'),
(2,6000.00,'2025-11-01','Cash'),
(2,6000.00,'2025-11-02','Card'),
(3,3000.00,'2025-09-09','UPI');


INSERT INTO Staff (hotel_id, name, role, salary) VALUES
(1,'Sangeeta','Manager',45000.00),
(1,'Ramesh','Receptionist',22000.00),
(2,'John','Housekeeping',18000.00);


SELECT * FROM Hotel;

SELECT room_no, type, price, status FROM Room;

SELECT name, phone FROM Guest;

SELECT b.booking_id, g.name, r.room_no, b.check_in, b.check_out, b.status
FROM Booking b
JOIN Guest g ON b.guest_id=g.guest_id
JOIN Room r ON b.room_id=r.room_id;

SELECT room_no, type, price FROM Room
WHERE hotel_id = (SELECT hotel_id FROM Hotel WHERE name='Sunrise Hotel')
AND status='available';

SELECT h.name, COUNT(r.room_id) AS total_rooms
FROM Hotel h JOIN Room r ON h.hotel_id=r.hotel_id
GROUP BY h.hotel_id;

SELECT SUM(amount) AS total_revenue FROM Booking;

SELECT h.name, SUM(b.amount) AS revenue
FROM Hotel h
JOIN Room r ON h.hotel_id=r.hotel_id
JOIN Booking b ON r.room_id=b.room_id
GROUP BY h.hotel_id;

SELECT type, AVG(price) AS avg_price FROM Room GROUP BY type;

SELECT g.name, COUNT(*) AS bookings
FROM Guest g JOIN Booking b ON g.guest_id=b.guest_id
GROUP BY g.guest_id
HAVING COUNT(*) > 1;

SELECT s.name, s.role, s.salary
FROM Staff s
WHERE (s.hotel_id, s.salary) IN (
SELECT hotel_id, MAX(salary) FROM Staff GROUP BY hotel_id
);

SELECT * FROM Room WHERE price > (SELECT AVG(price) FROM Room);

SELECT * FROM Guest WHERE guest_id IN (SELECT guest_id FROM Booking);

SELECT b.* FROM Booking b
WHERE EXISTS (SELECT 1 FROM Payment p WHERE p.booking_id=b.booking_id);

SELECT b.booking_id, b.amount AS booking_amount,
(SELECT COALESCE(SUM(p.amount),0) FROM Payment p WHERE p.booking_id=b.booking_id) AS paid
FROM Booking b
HAVING paid < booking_amount;

SELECT * FROM Hotel WHERE hotel_id IN (SELECT hotel_id FROM Room WHERE type='Suite');

SELECT DISTINCT g.* FROM Guest g
JOIN Booking b ON g.guest_id=b.guest_id
JOIN Payment p ON b.booking_id=p.booking_id
WHERE p.method='Card';

SELECT r.* FROM Room r
LEFT JOIN Booking b ON r.room_id=b.room_id
WHERE b.booking_id IS NULL;

SELECT g.name, b.booking_id, b.check_in FROM Guest g
JOIN Booking b ON g.guest_id=b.guest_id
WHERE b.check_in = (SELECT MAX(b2.check_in) FROM Booking b2 WHERE b2.guest_id = g.guest_id);

SELECT r.* FROM Room r
WHERE r.price > (SELECT AVG(r2.price) FROM Room r2 WHERE r2.hotel_id = r.hotel_id);

SELECT g.name, DATEDIFF(b.check_out, b.check_in) AS nights
FROM Booking b JOIN Guest g ON b.guest_id=g.guest_id
ORDER BY nights DESC LIMIT 5;

SELECT h.name,
(COUNT(DISTINCT b.room_id) / COUNT(r.room_id)) * 100 AS occupancy_percent
FROM Hotel h
JOIN Room r ON h.hotel_id=r.hotel_id
LEFT JOIN Booking b ON r.room_id=b.room_id
AND (b.check_in <= '2025-11-05' AND b.check_out >= '2025-11-01')
GROUP BY h.hotel_id;

SELECT name, revenue, RANK() OVER (ORDER BY revenue DESC) AS rev_rank
FROM (
SELECT h.name, COALESCE(SUM(b.amount),0) AS revenue
FROM Hotel h
LEFT JOIN Room r ON h.hotel_id=r.hotel_id
LEFT JOIN Booking b ON r.room_id=b.room_id
GROUP BY h.hotel_id
) t;

SELECT b.* FROM Booking b
WHERE b.amount > (SELECT AVG(b2.amount) FROM Booking b2 WHERE b2.guest_id=b.guest_id);

CREATE VIEW current_bookings AS
SELECT b.booking_id, g.name AS guest_name, r.room_no, b.check_in, b.check_out
FROM Booking b JOIN Guest g ON b.guest_id=g.guest_id JOIN Room r ON b.room_id=r.room_id
WHERE b.status IN ('confirmed','checked_in');

START TRANSACTION;
INSERT INTO Booking (guest_id, room_id, check_in, check_out, amount, status)
VALUES (1,4,'2025-12-01','2025-12-03',4000,'confirmed');
INSERT INTO Payment (booking_id, amount, payment_date, method) VALUES (LAST_INSERT_ID(),4000,'2025-11-20','Card');
UPDATE Room SET status='booked' WHERE room_id=4;
COMMIT;

CREATE INDEX idx_checkin ON Booking(check_in);


DELIMITER $$
CREATE PROCEDURE total_spend(IN gid INT)
BEGIN
SELECT SUM(amount) AS total FROM Booking WHERE guest_id = gid;
END$$
DELIMITER ;

SELECT h.name, COUNT(s.staff_id) AS staff_count
FROM Hotel h JOIN Staff s ON h.hotel_id=s.hotel_id
GROUP BY h.hotel_id HAVING COUNT(s.staff_id) > 2;

SELECT b.* FROM Booking b
WHERE b.room_id IN (
SELECT r.room_id FROM Room r
WHERE r.hotel_id IN (
SELECT hotel_id FROM (
SELECT hotel_id, AVG(price) AS avg_p FROM Room GROUP BY hotel_id
) AS t WHERE t.avg_p > (SELECT AVG(price) FROM Room)
)
);

