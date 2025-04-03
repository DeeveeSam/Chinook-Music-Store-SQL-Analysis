USE MusicStore;

--Identify the most senior employee based on job title to understand company hierarchy.
SELECT last_name, first_name, title
FROM employee
WHERE reports_to IS NULL;

--Determine the countries with the highest invoice counts to analyze market performance. 
SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

--Identify the top 3 invoices with the highest total amounts to assess high-value purchases.
 SELECT TOP 3 invoice_id, total
 FROM invoice
 ORDER BY total DESC;
 
--Find the city that generates the highest revenue.
SELECT TOP 1 billing_city, SUM(total) AS total_revenue
FROM invoice
GROUP BY  billing_city
ORDER BY total_revenue DESC;


--Determine the best customer based on total spending.
SELECT TOP 1 c.customer_id, first_name, last_name, SUM(i.total) AS total_money_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, first_name, last_name
ORDER BY total_money_spent DESC;


--Identify top rock music listeners based on their purchase history and segment them by email.
SELECT DISTINCT c.email,c.first_name, c.last_name
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
WHERE track_id IN(
					SELECT track_id 
					FROM track t
					JOIN genre g
					ON t.genre_id = g.genre_id
					WHERE g.name = 'Rock'
				 )
ORDER BY c.email;

--Find the customers who have spent on the best-selling artist.
WITH BestSellingArtist AS (  
							SELECT TOP 1 a.artist_id, a.name AS artist_name, SUM(il.unit_price * il.quantity) AS TotalRevenue  
							FROM artist a  
							JOIN album al 
							ON a.artist_id = al.artist_id 
							JOIN track t 
							ON al.album_id = t.album_id  
							JOIN invoice_line il 
							ON t.track_id = il.track_id  
							GROUP BY a.artist_id, a.name
							ORDER BY TotalRevenue DESC  
						  ),
	    CustomerInfo AS(
							SELECT first_name, last_name, al.artist_id, SUM(il.unit_price * il.quantity) AS AmountSpent
							FROM customer c
							JOIN invoice i
							ON c.customer_id = i.customer_id
							JOIN invoice_line il
							ON i.invoice_id = il.invoice_id
							JOIN track t 
							ON il.track_id = t.track_id
							JOIN album al 
							ON t.album_id = al.album_id 
							GROUP BY first_name, last_name,   al.artist_id
	                    )

SELECT ci.first_name, ci.last_name, bsa.artist_name ,ci.AmountSpent 
FROM CustomerInfo ci
JOIN BestSellingArtist bsa
ON ci.artist_id = bsa.artist_id
ORDER BY ci.AmountSpent DESC;

--Identify the top-spending customer for each country, ensuring fair representation in regional customer loyalty programs.
WITH CustomerSpending AS (  
							SELECT c.country, c.first_name, c.last_name, SUM(i.total) AS TotalSpent,  
								   RANK() OVER (PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS ranking  
							FROM Customer c  
							JOIN Invoice i 
							ON c.customer_id = i.customer_id  
							GROUP BY c.country, c.first_name, c.last_name  
						)  
SELECT country, first_name, last_name, TotalSpent  
FROM CustomerSpending  
WHERE ranking = 1  
ORDER BY Country;

--Identify the top 10 rock bands with the highest number of tracks.
WITH RockArtists AS (  
						SELECT a.artist_id, a.Name AS artist_name, COUNT(t.track_id) AS track_count  
						FROM Artist a  
						JOIN Album al 
						ON a.artist_id = al.artist_id 
						JOIN Track t 
						ON al.album_id = t.album_id  
						JOIN Genre g 
						ON t.genre_id = g.genre_id  
						WHERE g.Name = 'Rock'  
						GROUP BY a.artist_id, a.Name  
)  
SELECT TOP 10 * 
FROM RockArtists  
ORDER BY track_count DESC;

--Find all songs longer than the average song length to analyze song duration trends.
SELECT name, milliseconds  
FROM track  
WHERE milliseconds > 
					(SELECT AVG(Milliseconds)
					 FROM Track)  
ORDER BY milliseconds DESC;

--Determine the most popular music genre for each country.
WITH GenreSales AS (  
						SELECT c.country AS Country, g.name AS Genre, COUNT(il.invoice_line_id) AS PurchaseCount,  
								RANK() OVER (PARTITION BY c.country ORDER BY COUNT(il.invoice_line_id) DESC) AS ranking 
						FROM customer c  
						JOIN invoice i 
						ON c.customer_id = i.customer_id
						JOIN invoice_line il 
						ON i.invoice_id = il.invoice_id  
						JOIN Track t 
						ON il.track_id = t.track_id  
						JOIN Genre g 
						ON t.genre_id = g.genre_id  
						GROUP BY c.Country, g.name  
				   )  

SELECT Country, Genre, PurchaseCount  
FROM GenreSales  
WHERE ranking = 1  
ORDER BY Country;
