 #!/bin/bash
# Julia Buniak

dbname="ibuniak"
read -p "Enter you first and last name > " first last 
echo "Hello, $first $last,"
echo "Welcome to Smart Car Rentals!"
echo
echo "Pick the option what you want to do next:"
echo 

displayOptions() {
echo "Check available cars                 ==========> [A]" #M
echo "Book a car                           ==========> [B]" #J+
echo "Check rented cars                    ==========> [C]" #J+
echo "Check out a car                      ==========> [D]" #J
echo "Car return                           ==========> [E]" #M
echo "Add employee information             ==========> [F]" #J
echo "List all employees                   ==========> [G]" #J 
echo "Find an employee                     ==========> [H]" #M
echo "Add customer information             ==========> [I]" #M
echo "List all customers                   ==========> [J]" #M
echo "Find a customer                      ==========> [K]" #M
echo "Extra charge                         ==========> [L]" #J
echo "Search a car                         ==========> [S]"
echo "To quit                              ==========> [Q]"
echo
}


pickA()
{
# Matt
#enter  date_out and return_date
#compare these dates
psql $dbname << EOF 
SELECT * FROM car_tbl WHERE status = 'Available';
EOF
}


pickB()
{
# add constraint that you cannot book the same car for the same period
echo
echo  "Booking a car"
echo   
read -p "Enter customer ID number > " customer_id
read -p "Enter car ID number > " car_id
read -p "Enter payment ID > " payment_id
read -p "Starting date of rent (YYYY-MM-DD) > " date_out
read -p "Date when the car should be returned (YYYY-MM-DD) > " return_date

psql $dbname << EOF 
INSERT INTO booking_tbl(customer_id, car_id, payment_id, date_out, return_date) 
VALUES 
('$customer_id', '$car_id', '$payment_id', '$date_out', '$return_date');
EOF

last_id=$(psql -d ${dbname} -t -c "SELECT last_value from booking_tbl_booking_id_seq" )

echo  
echo "Here is information about your booking: "
echo 

psql $dbname << EOF 
SELECT ctm.first_name, ctm.last_name, car.make, car.model, car.type, car.color, p.credit_card_number, b.date_out, b.return_date 
FROM  customer_tbl ctm, car_tbl car, booking_tbl b, payment_tbl p 
WHERE b.booking_id = $last_id
AND b.car_id = car.car_id
AND b.customer_id = ctm.customer_id
AND b.payment_id = p.payment_id;
EOF
}

#method to check rented cars
pickC()
{
#Julia
echo "Checking the rented cars for chosen date" 
echo
read -p "Enter the date (YYYY-MM-DD) > " date
psql $dbname << EOF 
SELECT  c.car_id, c.year, c.license_plate, c.make, c.model, c.type, c.color, b.date_out, b.return_date
FROM car_tbl c INNER JOIN booking_tbl b
ON c.car_id = b.car_id
WHERE date_out <= '$date'::date AND return_date >= '$date'::date;
EOF
}

# method to check out a car 
pickD()
{
echo 
echo "Checking out a car"
echo
read -p "Enter booking ID number > " booking_id
read -p "Enter employee ID number > " employee_id
read -p "Enter insurance ID number > " insurance_id
#read -p "Enter today day (YYYY-MM-DD) > " invoice_out
#read -p "Enter current charge > " return_date # get this number from booking_tbl

 
days=$(psql -d ${dbname} -t -c "SELECT number_of_days from booking_tbl WHERE booking_id = $booking_id" )
car_id=$(psql -d ${dbname} -t -c "SELECT car_id from booking_tbl WHERE booking_id = $booking_id" )
rate=$(psql -d ${dbname} -t -c "SELECT rate from car_tbl WHERE car_id = $car_id" )
#charge=$(psql -d ${dbname} -t -c "SELECT check_out_charge($bookingid)" )
charge=$(awk "BEGIN {printf \"%.2f\", ${days}*${rate}}") 

psql $dbname << EOF 
INSERT INTO check_out_tbl(booking_id, employee_id, insurance_id, invoice_date, charge) 
VALUES 
($booking_id, $employee_id, $insurance_id, now(), $charge);
EOF

last_id=$(psql -d ${dbname} -t -c "SELECT last_value from check_out_tbl_check_out_id_seq" )

echo  
echo "Here is information about your check out: "
echo 

psql $dbname << EOF 
SELECT ctm.first_name, ctm.last_name,car.make, car.model, b.date_out, b.return_date, b.number_of_days, ch.invoice_date, ch.charge, ch.sales_tax, ch.total
FROM  customer_tbl ctm, car_tbl car, booking_tbl b, check_out_tbl ch 
WHERE check_out_id = $last_id
AND ch.booking_id = b.booking_id
AND b.customer_id = ctm.customer_id 
AND b.car_id = car.car_id;
EOF

}



displayOptions
echo 
read -p "Enter appropriate option >  " reply
while [[ $reply  != "Q" && $reply  != "q" ]] 
do 
case $reply in
      A|a) pickA;;
      B|b) pickB;;
      C|c) pickC;;
      D|d) pickD;;
      E|e) pickE;;
      F|f) pickF;;
      G|g) pickG;;
      H|h) pickH;;
      I|i) pickI;;
      J|j) pickJ;;
      K|k) pickK;; 
      L|l) pickL;;
      S|s) pickS;;
      Q|q) exit;;
      *) echo "Invalid choice!"; exit;;
 esac
echo "Now you can exit the menu (press Q for that) or pick another option"
displayOptions
read -p "Enter appropriate option >  " reply
done
echo
