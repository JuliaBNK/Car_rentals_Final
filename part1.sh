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
echo "Check out a car                      ==========> [D]" #J+
echo "Car return                           ==========> [E]" #M
echo "Add employee information             ==========> [F]" #J+
echo "List all employees                   ==========> [G]" #J+
echo "Find an employee                     ==========> [H]" #M
echo "Add customer information             ==========> [I]" #M
echo "List all customers                   ==========> [J]" #M
echo "Find a customer                      ==========> [K]" #M
echo "Extra charge                         ==========> [L]" #J+
echo "Invoice for last return              ==========> [O]" #M
echo "Update  odometer                     ==========> [U]" #M 
echo "To quit                              ==========> [Q]"
echo
}


pickB()
{
# add constraint that you cannot book the same car for the same period

echo
echo  "Booking a car"
echo   
#user input
read -p "Enter customer ID number > " customer_id
read -p "Enter car ID number > " car_id
read -p "Enter credit card number > " creadit_card_number
read -p "Enter credit card expiration year(YYYY) > " year
read -p "Enter credit card expiration month(MM) > " month
day="01"
date=$year$month$day
read -p "Starting date of rent (YYYY-MM-DD) > " date_out
read -p "Date when the car should be returned (YYYY-MM-DD) > " return_date

# add a new record into 
psql $dbname << EOF
 
INSERT INTO payment_tbl (credit_card_number, credit_card_exp_date, customer_id)
VALUES  
('$creadit_card_number', TO_DATE('$date', 'YYYYMMDD'), '$customer_id'); 
EOF

last_payment_id=$(psql -d ${dbname} -t -c "SELECT last_value from payment_tbl_payment_id_seq" )

count=$(psql -d ${dbname} -t -c "SELECT count(*) FROM booking_tbl WHERE car_id = $car_id AND ((date_out < '$date_out'::date AND return_date > '$return_date'::date) OR (date_out < '$date_out'::date AND return_date < '$return_date'::date) OR (date_out > '$date_out'::date AND return_date < '$return_date'::date) OR(date_out > '$date_out'::date AND return_date > '$return_date'::date)) " )
echo "Count = "$count

while [[ $count -gt 0 ]]
do
echo "This car is already booked for these dates. Try to book another car!"
read -p "Enter car ID number > " car_id
count=$(psql -d ${dbname} -t -c "SELECT count(*) FROM booking_tbl WHERE car_id = $car_id AND ((date_out < '$date_out'::date AND return_date > '$return_date'::date) OR (date_out < '$date_out'::date AND return_date < '$return_date'::date) OR (date_out > '$date_out'::date AND return_date < '$return_date'::date) OR(date_out > '$date_out'::date AND return_date > '$return_date'::date)) " )
done


psql $dbname << EOF 
INSERT INTO booking_tbl(customer_id, car_id, payment_id, date_out, return_date) 
VALUES 
('$customer_id', '$car_id', '$last_id', '$date_out', '$return_date');
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
# to calculate the total amount with extra charge
# to calculate the ins payment
pickD()
{
echo 
echo "Checking out a car"
echo
read -p "Enter booking ID number > " booking_id
read -p "Enter employee ID number > " employee_id
read -p "Enter insurance ID number > " insurance_id

 
days=$(psql -d ${dbname} -t -c "SELECT number_of_days from booking_tbl WHERE booking_id = $booking_id" )
car_id=$(psql -d ${dbname} -t -c "SELECT car_id from booking_tbl WHERE booking_id = $booking_id" )
rate=$(psql -d ${dbname} -t -c "SELECT rate from car_tbl WHERE car_id = $car_id" )
ins_rate=$(psql -d ${dbname} -t -c "SELECT day_rate from insurance_type_tbl WHERE type_id = (SELECT type_id FROM ins_tbl WHERE ins_id = $insurance_id)" )

charge=$(awk "BEGIN {printf \"%.2f\", ${days}*${rate}}") 
ins_payment=$(awk "BEGIN {printf \"%.2f\", ${days}*${ins_rate}}") 

psql $dbname << EOF 
INSERT INTO check_out_tbl(booking_id, employee_id, insurance_id, invoice_date, charge, ins_payment) 
VALUES 
($booking_id, $employee_id, $insurance_id, current_date, $charge, $ins_payment);
EOF

last_id=$(psql -d ${dbname} -t -c "SELECT last_value from check_out_tbl_check_out_id_seq" )

echo  
echo "Here is information about your check out: "
echo 

psql $dbname << EOF 
SELECT ctm.first_name, ctm.last_name,car.make, car.model, b.date_out, b.return_date, b.number_of_days, ch.invoice_date, ch.charge, ch.ins_payment,  ch.sales_tax, ch.total
FROM  customer_tbl ctm, car_tbl car, booking_tbl b, check_out_tbl ch 
WHERE check_out_id = $last_id
AND ch.booking_id = b.booking_id
AND b.customer_id = ctm.customer_id 
AND b.car_id = car.car_id;
EOF

}


pickE()
{
#Car Return


read -p "Enter your Employee ID:  " return_employee_id
read -p "Enter the Car ID you are returning:  " return_car_id
read -p "Enter the Customer ID:  " return_customer_id
#odometer=$(psql -d ${dbname} -t -c "SELECT odometer from car_tbl where car_id = $return_car_id" )
read -p "Enter the new milage:  " milage_in                     #Trigger Calculate miles total or if elif statement

#while [[ $milage_in -le $odometer ]];
#do 
#echo "New mileage cannot be less than previous odometer reading."
#
#read -p "Enter the new milage:  " milage_in   
#done

read -p "How many gallons of gas did we add to fill:  " gallons_gas_filled
read -p "How much did the gas cost per gallon:  " gas_price_per_gallon
read -p "Do you have any notes for this rental?  " rental_notes
echo "employeeID: " $return_employee_id  "returncarID: " $return_car_id  "customerID: " $return_customer_id  "Your milage in: " $milage_in
echo "Gallons Filled by us:"  $gallons_gas_filled  "Price per gallon: " $gas_price_per_gallon  "Rental notes: " $rental_notes

psql $dbname <<EOF
INSERT INTO return_tbl(car_id, customer_id, employee_id, new_mileage, gas_refill, price_per_gallon, notes)
VALUES ($return_car_id, $return_customer_id, $return_employee_id, $milage_in, $gallons_gas_filled, $gas_price_per_gallon, '$rental_notes');
EOF
}




#function to add employee information 
pickF()
{
 echo
 echo "Adding employee information "
 echo

read -p "Enter first name > " first
read -p "Enter middle name > " middle  
read -p "Enter last name > " last 
read -p "Enter phone number (just digits without dashes) > " phone
read -p "Enter email > " email
read -p "Enter street number > " address
read -p "Enter city name > " city 
read -p "Enter state (i.e CA, NY) > " state
read -p "Enter zip > " zip
read -p "Enter date of birth (YYYY-MM-DD) > " dob
read -p "Enter the gender > " gender 
read -p "Enter employee's position > " position
echo  
echo "You have added a new employee: "
echo 
psql $dbname << EOF 
INSERT INTO employee_tbl(last_name, middle_name, first_name, phone, email, address, city, state, zip, dob, gender, position) 
VALUES 
('$last', '$middle', '$first', '$phone', '$email', '$address', '$city', '$state', '$zip', '$dob', '$gender', '$position' );
EOF

last_id=$(psql -d ${dbname} -t -c "SELECT last_value from employee_tbl_employee_id_seq" )

psql $dbname << EOF 
SELECT first_name, middle_name, last_name, phone, email, address, city, state, zip, dob, gender, position
FROM  employee_tbl
WHERE employee_id = $last_id;
EOF
 
}



#Julia Buniak
#Function to list all employees 

pickG() {
echo
echo "All employees"
echo

psql $dbname << EOF 
SELECT * FROM employee_tbl;
EOF
}

#Julia Buniak
#Function to calculate extra charge
# add invoice 
pickL() {
echo
echo "Extra charge"
echo

read -p "Enter return id > "  return_id
read -p "Enter extra charge id > " extra_charge_id 
while [[ $extra_charge_id  != "Q" && $extra_charge_id  != "q" ]] 
do 
psql $dbname << EOF 
INSERT INTO return_extra_charge_tbl(return_id, extra_charge_id)
VALUES 
('$return_id', '$extra_charge_id');
EOF
echo "Now you can enter another extra charge or enter 'Q' to exit"
read -p "Enter extra charge id > " extra_charge_id 
done

psql $dbname << EOF  
DROP View  extra_charge_view;
CREATE View  extra_charge_view AS
SELECT r.return_id, c.first_name, c.last_name, car.make, e.description, e.charge
FROM EXTRA_CHARGE_TBL e,  RETURN_TBL r, CAR_TBL car, CUSTOMER_TBL c, RETURN_EXTRA_CHARGE_TBL re 
WHERE re.return_id = $return_id
AND  re.return_id = r.return_id
AND  r.car_id = car.car_id
AND r.customer_id = c.customer_id
AND re.extra_charge_id = e.extra_charge_id;
GRANT SELECT, INSERT, UPDATE, DELETE on extra_charge_view to mmims;
SELECT * FROM extra_charge_view;
EOF


extra=$(psql -d ${dbname} -t -c "SELECT SUM(charge) FROM extra_charge_view")
echo " Extra charge to be paid: $" $extra

psql $dbname << EOF
BEGIN;
UPDATE return_tbl SET extra_charge = $extra where return_id = $return_id;
UPDATE return_tbl SET total = $extra + (SELECT  gas_total  FROM return_tbl  WHERE return_id = $return_id) WHERE return_id = $return_id;  
SELECT  * from car_tbl where car_id = get_car_id_last_id();
COMMIT
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
      O|o) pickO;;
      U|u) pickU;;
      Q|q) exit;;
      *) echo "Invalid choice!"; exit;;
 esac
echo "Now you can exit the menu (press Q for that) or pick another option"
displayOptions
read -p "Enter appropriate option >  " reply
done
echo


