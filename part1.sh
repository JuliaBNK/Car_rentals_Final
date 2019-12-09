 #!/bin/bash

dbname="ibuniak"
read -p "Enter you first and last name > " first last 
echo "Hello, $first $last,"
echo "Welcome to Smart Car Rentals!"
echo
echo "Pick the option what you want to do next:"
echo 

displayOptions() {
echo "Check available cars                 ==========> [A]" #M J
echo "Book a car                           ==========> [B]" #J
echo "Check rented cars                    ==========> [C]" #J
echo "Check out a car                      ==========> [D]" #J
echo "Car return                           ==========> [E]" #M
echo "Add employee information             ==========> [F]" #J
echo "List all employees                   ==========> [G]" #J
echo "Find an employee                     ==========> [H]" #M
echo "Add customer information             ==========> [I]" #M
echo "List all customers                   ==========> [J]" #M
echo "Find a customer                      ==========> [K]" #M
echo "Extra charge                         ==========> [L]" #J
echo "To print the invoice                 ==========> [O]" #M
echo "Update  odometer                     ==========> [U]" #M 
echo "To quit                              ==========> [Q]"
echo
}

#Matthew Mims, Julia Buniak
#function to chack available cars for certain period 
pickA()
{
read -p "Enter date out >" date_out
read -p "Enter return date >" return_date

psql $dbname << EOF

select distinct c.car_id, c.year, c.make, c.model, c.type,c.color, c.rate
FROM car_tbl c FULL JOIN booking_tbl b
ON c.car_id = b.car_id
WHERE c.car_id NOT IN   (select c.car_id
 			FROM car_tbl c FULL JOIN booking_tbl b
			ON c.car_id = b.car_id
			where  (date_out <= '$date_out'::date AND return_date >= '$return_date'::date)
			OR (date_out <= '$date_out'::date AND return_date <= '$return_date'::date AND return_date >= '$date_out'::date) 
			OR (date_out >= '$date_out'::date AND return_date <= '$return_date'::date)
			OR (date_out >= '$date_out'::date AND return_date >= '$return_date'::date AND date_out <= '$return_date'::date)
			group by c.car_id);
EOF
}


#Julia Buniak
# function to book a car 
pickB()
{
echo
echo  "Booking a car"
echo

#user input
read -p "Enter customer ID number > " customer_id
read -p "Enter car ID number > " car_id
read -p "Enter credit card number > " credit_card_number
read -p "Enter credit card expiration year(YYYY) > " year
read -p "Enter credit card expiration month(MM) > " month
day="01"
date=$year$month$day
read -p "Starting date of rent (YYYY-MM-DD) > " date_out
read -p "Date when the car should be returned (YYYY-MM-DD) > " return_date


count=$(psql -d ${dbname} -t -c "SELECT count(*) FROM booking_tbl WHERE car_id = $car_id AND ((date_out <= '$date_out'::date AND return_date >= '$return_date'::date) OR (date_out <= '$date_out'::date AND return_date <= '$return_date'::date AND return_date >= '$date_out'::date) OR (date_out >= '$date_out'::date AND return_date <= '$return_date'::date) OR (date_out >= '$date_out'::date AND return_date >= '$return_date'::date AND date_out <= '$return_date'::date)) " )

while [[ $count -gt 0 ]]
do
echo "This car is already booked for these dates. Try to book another car!"
read -p "Enter car ID number > " car_id
count=$(psql -d ${dbname} -t -c "SELECT count(*) FROM booking_tbl WHERE car_id = $car_id AND ((date_out <= '$date_out'::date AND return_date >= '$return_date'::date) OR (date_out <= '$date_out'::date AND return_date <= '$return_date'::date AND return_date >= '$date_out'::date) OR (date_out >= '$date_out'::date AND return_date <= '$return_date'::date) OR(date_out >= '$date_out'::date AND return_date >= '$return_date'::date AND date_out <= '$return_date'::date)) " )
done

# add a new record into payment_tbl 
psql $dbname << EOF 

INSERT INTO payment_tbl (credit_card_number, credit_card_exp_date, customer_id)
VALUES ('$credit_card_number', TO_DATE('$date', 'YYYYMMDD'), $customer_id);
EOF

payment_id=$(psql -d ${dbname} -t -c "SELECT last_value from payment_tbl_payment_id_seq" )

#display information about last booking
echo  
echo "Here is information about your booking: "
echo 

#add  booking into booking_tbl
psql $dbname << EOF 
BEGIN;
INSERT INTO booking_tbl(customer_id, car_id, payment_id, date_out, return_date) 
VALUES ($customer_id, $car_id, $payment_id, '$date_out', '$return_date');

SELECT ctm.first_name, ctm.last_name, car.make, car.model, car.type, car.color, p.credit_card_number, b.date_out, b.return_date 
FROM  customer_tbl ctm, car_tbl car, booking_tbl b, payment_tbl p 
WHERE b.booking_id = (SELECT last_value from booking_tbl_booking_id_seq)
AND b.car_id = car.car_id
AND b.customer_id = ctm.customer_id
AND b.payment_id = p.payment_id;
COMMIT;
EOF
}

#Julia Buniak
#method to check what cars are rented out for specific day
pickC()
{
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

#Julia Buniak
# method to check out a car 
# to calculate the total amount with extra charge
pickD()
{
echo 
echo "Checking out a car"
echo
read -p "Enter booking ID number > " booking_id
read -p "Enter employee ID number > " employee_id
read -p "Enter insurance company > " company
read -p "Enter policy number > " policy_number
read -p "Enter insurance type: 1 for purchased or 2 for customer personal insurance > " type_id

customer_id=$(psql -d ${dbname} -t -c "SELECT customer_id from booking_tbl WHERE booking_id = $booking_id" )

#add a new record into ins_tbl 
psql $dbname << EOF 

INSERT INTO ins_tbl (customer_id, company, policy_number, type_id)
VALUES ($customer_id, '$company', '$policy_number', $type_id);
EOF

last_ins_id=$(psql -d ${dbname} -t -c "SELECT last_value from ins_tbl_ins_id_seq" ) 

days=$(psql -d ${dbname} -t -c "SELECT number_of_days from booking_tbl WHERE booking_id = $booking_id" )
rate=$(psql -d ${dbname} -t -c "SELECT rate from car_tbl WHERE car_id = (SELECT car_id from booking_tbl WHERE booking_id = $booking_id)" )
ins_rate=$(psql -d ${dbname} -t -c "SELECT day_rate from insurance_type_tbl WHERE type_id = (SELECT type_id FROM ins_tbl WHERE ins_id =(SELECT last_value from ins_tbl_ins_id_seq))" )

# to calculate the base payment for booked days (formula: days * rate)
charge=$(awk "BEGIN {printf \"%.2f\", ${days}*${rate}}") 
# to calculate the ins payment for booked days (formula: days * ins_rate)
ins_payment=$(awk "BEGIN {printf \"%.2f\", ${days}*${ins_rate}}") 


#insert current check out into check_out_tbl
psql $dbname << EOF 
INSERT INTO check_out_tbl(booking_id, employee_id, insurance_id, invoice_date, charge, ins_payment) 
VALUES 
($booking_id, $employee_id, $last_ins_id, current_date, $charge, $ins_payment);
EOF



#display info about last check_out
echo  
echo "Here is information about your check out: "
echo 

psql $dbname << EOF 
SELECT ctm.first_name, ctm.last_name,car.make, car.model, b.date_out, b.return_date, b.number_of_days, ch.invoice_date, ch.charge, ch.ins_payment,  ch.sales_tax, ch.total
FROM  customer_tbl ctm, car_tbl car, booking_tbl b, check_out_tbl ch 
WHERE check_out_id = (SELECT last_value from check_out_tbl_check_out_id_seq)
AND ch.booking_id = b.booking_id
AND b.customer_id = ctm.customer_id 
AND b.car_id = car.car_id;
EOF
}

#Matthew Mims
#Function for Car Return
pickE()
{
#Car Return
read -p "Enter your Employee ID:  " return_employee_id
read -p "Enter the Car ID you are returning:  " return_car_id
read -p "Enter the Customer ID:  " return_customer_id
read -p "Enter the new milage:  " milage_in
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


#Julia Buniak
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

echo  
echo "Here is information about a new employee: "
echo 

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

#Matthew Mims
#Find an employee
pickH()
{
read -p "Find all information on an employee.  Enter the employee's ID:  " find_emp_id

psql $dbname << EOF
select * from employee_tbl where employee_id = $find_emp_id;
EOF
}

#Matthew Mims
# Function to add customer information to customer_tbl
pickI()
{
read -p "Enter the last name of the customer:  " add_lastname
read -p "Enter the middle name:  " add_middlename
read -p "Enter the first name:  " add_firstname
read -p "Enter the drivers licence:  " add_licence
read -p "Enter the phone:  " add_phonenumber
read -p "Enter the email:  " add_email
read -p "Enter the address:  " add_address
read -p "Enter the city:  " add_city
read -p "Enter the state:  " add_state
read -p "Enter the zipcode:  " add_zipcode
read -p "Enter the country:  " add_country
read -p "Enter the date of birth:  " add_dob
read -p "Enter the gender:  " add_gender
read -p "Enter any notes for this customer:  " add_notes

echo "customer_id: " $customer_id
echo "returncarID: " $return_car_id
echo "last name:"  $add_lastname
echo "middle name: " $add_middlename
echo "first name: " $add_firstname
echo "drivers licence: " $add_licence
echo "phone: " $add_phonenumber
echo "email: " $add_email
echo "address: " $add_address
echo "city: " $add_city
echo "state: " $add_state
echo "zipcode: " $add_zipcode
echo "country: " $add_country
echo "date of birth: " $add_dob
echo "gender: " $add_gender
echo "notes: " $add_notes
read -p "Do you want to insert this customer's records into the customer_tbl?"
read -p "If so, then press the enter key to enter your password and insert these records."

psql $dbname << EOF
INSERT INTO Customer_tbl(last_name, middle_name, first_name, driver_licence, phone, email, address, city, state, zip, country, dob, gender, notes)
VALUES ('$add_lastname', '$add_middlename', '$add_firstname', '$add_licence', '$add_phonenumber', '$add_email', '$add_address', '$add_city',
                '$add_state', '$add_zipcode', '$add_country', '$add_dob', '$add_gender', '$add_notes');
EOF
}

#Matthew Mims
#List all customers in the customer_tbl
pickJ()
{
read -p "Press enter to input your password and see the list of customers:"

psql $dbname << EOF
select * from customer_tbl;
EOF
}

#Matthew Mims
#Find a customer in the data base
pickK()
{
read -p "Enter the customers last name to view their information:" customer_information

psql $dbname << EOF
SELECT last_name, first_name, credit_card_number, company, policy_number, phone, email, city, dob, date_out, number_of_days
FROM customer_tbl c 
INNER JOIN booking_tbl b
	ON c.customer_id = b.customer_id
INNER JOIN payment_tbl p
	ON c.customer_id = p.customer_id
INNER JOIN ins_tbl i
	ON c.customer_id = i.customer_id
WHERE last_name = '$customer_information';
EOF

}



#Julia Buniak
#Function to calculate extra charge
pickL() {
echo
echo "Extra charge"
echo
#return_id is connected to a customer and a car
read -p "Enter return id > "  return_id
read -p "Enter extra charge id > " extra_charge_id 
read -p "Enter check out id > " check_out_id

#add necessary extra charges to database
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

#create view through wich we can calculate the total amount for extra charges
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

# add total amount of extra charges to return_tb
# calculate the total amount needs to be paid during return (gas_total + extra charges)
psql $dbname << EOF
BEGIN;
UPDATE return_tbl SET check_out_id = $check_out_id  where return_id = $return_id; 
UPDATE return_tbl SET extra_charge = $extra where return_id = $return_id;
UPDATE return_tbl SET total = $extra + (SELECT  gas_total  FROM return_tbl  WHERE return_id = $return_id) WHERE return_id = $return_id;  
COMMIT
EOF
}

#Matthew Mims
#Function to show the invoice
pickO()
{
read -p "Enter return_id to print the invoice:  " return_id_input

psql $dbname << EOF


SELECT distinct r.return_id as RID, r.employee_id as EID, p.payment_id as PID, ctm.first_name as First, ctm.last_name as Last,
           b.number_of_days as Days, car.rate, r.price_per_gallon as PerGal, r.gas_refill as Gallons, r.gas_total,
           r.extra_charge, chk.ins_payment, chk.charge, chk.sales_tax, chk.ins_payment, chk.total,
           (select chk.total + r.total) as invoice_total
FROM return_tbl r,  booking_tbl b, customer_tbl ctm, car_tbl car,  payment_tbl p, check_out_tbl chk
WHERE r.return_id = $return_id_input
AND r.check_out_id = chk.check_out_id
AND chk.booking_id = b.booking_id
AND b.customer_id = ctm.customer_id
AND b.car_id = car.car_id
AND b.payment_id = p.payment_id;

EOF

}

#Matthew Mims
#Function to update the odometer
pickU()
{

read -p "Press enter if you want to insert the new_mileage into the car_tbl: "
read -p "Enter car_id to update it's new_milage in the car_tbl:   >>" get_car_id

psql $dbname << EOF

begin;
select c.odometer as original_miles_updated, r.new_mileage as new_return_miles
from car_tbl c, return_tbl r where c.car_id = r.car_id and c.car_id = $get_car_id;
update car_tbl
	set odometer = return_tbl.new_mileage
	from return_tbl
	where car_tbl.car_id = return_tbl.car_id
	and car_tbl.car_id = $get_car_id;
select c.odometer as _miles, r.new_mileage as new_return_miles
from car_tbl c, return_tbl r where c.car_id = r.car_id and c.car_id = $get_car_id;
commit;
EOF

}


#Julia Buniak
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
      O|o) pickO;;
      U|u) pickU;;
      Q|q) exit;;
      *) echo "Invalid choice!"; exit;;
esac
echo "Now you can exit the menu (press Q for that) or pick another option"
displayOptions
read -p "Enter appropriate option >  " reply
done

