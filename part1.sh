#!/bin/bash
# Julia Buniak

dbname="ibuniak"
read -p "Enter you first and last name > " first last 
echo "Hello, $first $last,"
echo "Welcome to Smart Car Rentals!"
echo "Pick the option what you want to do next:"

displayOptions() {
echo "Check currently available cars       ==========> [A]" #M
echo "Book a car                           ==========> [B]" #J
echo "Check currently rented cars          ==========> [C]" #J
echo "Check out a car                      ==========> [D]" #J
echo "Car return                           ==========> [E]" #M
echo "Add employee information             ==========> [F]" #J
echo "List all employees                   ==========> [G]" #J 
echo "Find an employee                     ==========> [H]" #M
echo "Add customer information             ==========> [I]" #M
echo "List all customers                   ==========> [J]" #M
echo "Find a customer                      ==========> [K]" #M
echo "Extra charge                         ==========> [L]" #J
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
echo  "Booking of a car"
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

# TO DO
# create a trigger and count number of days
# calculate 
EOF
}

pickC()
{
#Julia
#enter  date_out and return_date
#compare these dates
psql $dbname << EOF 
SELECT * FROM car_tbl WHERE  status = 'Rented';;
EOF
}

pickD()
{ 
read -p "Enter car ID number > " car_id
read -p "Enter booking ID number > " booking_id
read -p "Enter customer ID number > " customer_id
read -p "Enter employee ID number > " employee_id
read -p "Enter insurance ID number > " insurance_id
read -p "Enter payment ID > " payment_id
read -p "Enter today day (YYYY-MM-DD) > " invoice_out
read -p "Enter current charge > " return_date # get this number from booking_tbl
 
psql $dbname << EOF 
INSERT INTO booking_tbl(customer_id, car_id, payment_id, date_out, return_date) 
VALUES 
('$customer_id', '$car_id', '$payment_id', '$date_out', '$return_date');

# create a trigger and count number of days
EOF
}



read -p "Enter appropriate option >  " reply
while [[ $reply  != "Q" && $reply  != "q" ]] 
do 
case $reply in
      A|a) pickA;;
      B|b) pickB;;
      R|r) pickR;;
      O|o) pickO;;
      N|n) pickN;;
      E|e) pickE;;
      F|f) pickF;;
      L|l) pickL;; 
      C|c) pickC;;
      Q|q) exit;;
      *) echo "Invalid choice!"; exit;;
 esac
echo "Now you can exit the menu (press Q for that) or pick another option"
read -p "Enter appropriate option >  " reply
done
echo
