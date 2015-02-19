## CartoDB Tutorial

CartoDB is a web-based tool for visalizing and analyzing
small to medium sized spatial datasets. While ostensibly open-source
software, it is quite difficult to compile yourself and much of
the nice UI is actually proprietary. Fortunately, they offer a
good free-tier of the service (no credit card needed; just an e-mail)
which should suffice for the purposes of this tutorial.

### Working with Openpaths data in CartoDB

Importing data to CartoDB is, in theory, very easy. Just drag
and drop the file you want into the dashboard and you're done!
Openpaths provides an option for exporting data as either a kml
file or a csv file. Both are supported by CartoDB, but I have
found that with the kml file the time attribute does not get
parsed correctly, so I recommend using the csv option.

The data view shows a tabular representation of the data we
loaded into CartoDB. The program has already detected which
columns coorispond to latitude and longitude and has created
variables called `the_geom` and `the_geom_webmercator`. These
are special data types that tell CartoDB where each row should
be mapped. There is also a column called `cartodb_id` with a
unique identifier for each row; we will use this a bit in this
tutorial, but it is particularly useful when integrating with
PHP and Javascript. The data types for the columns from the csv
file have also been automatically detected. Take note of these
as they will be important later.

Switching to the map view, we begin to see the benefits of using
a tool like CartoDB. A reasonably nice map has been constructed
out of the box from the data we imported. Zooming in and out,
you'll notice that the map has discrete zoom levels. That's because
the map is being created by a tile server which serves rasterized
tiles to the browser. Feel free to play around with the base map
and to tweak the look of the points with the visualization wizard.
I like to remove the border around the points for a cleaner look.
If we apply color, we can use quantiles of the timestamp or id to
create a sense of time on the map.

One of the best improvements the CartoDB since I started using it,
is the inclusion of a visualization called `torque`. It adds a much
better dimension of temporality to the data than possible from
color alone. It is particularly helpful for
natively spatio-temporal like the output from Openpaths. If we
do a heatmap torque, which does look very nice, what is the heatmap
suppose to represent?

Other than space and time, the Openpaths data does not give us much
more information about the points. So let's add a new column and
manually supply some info.
- clear the view
- add column (bottom right) called label
- set label equal to "HOME" for appropriate point (id 398)
- set label equal to "WORK" for appropriate point (id 106)
Now, go back to the map view. If we open the css tab, we see that
the wizard we previously used was simply creating code in this tab.
We can add custom code for calling out home and work:
```{css}
#openpaths_nolauren [ label = "HOME"] {
  marker-fill: #FFFFB2;
  marker-width: 100;
}
#openpaths_nolauren [ label = "YALE"] {
  marker-fill: #000000;
  marker-width: 100;
}
```
We can create a legend for these two points using the legend
tab. Finally, using the visualization button in the top right,
we can save and publish this map. The resulting url can be
distributed for access to anyone with the link.

### Galileo data

Galileo is another app for collecting data from a mobile device.
It uses GPS, and provides a much more grainular view of the trajectory
of the user. Galielo does natively allow for exporting as a csv,
and unfortunately the kml file is not readable by CartoDB (it creates
a dataset with only one point). I've written an R script contained in
this repository called `convertGalileo.R` for converting the kml
file into a csv file which we can load directly into CartoDB the same
way we did for Openpaths.

We'll proceed directly to contructing a visualization from this data.
There are so many densly packed points that we need to tweak the defaults
in order to see everything. How does this view differ from the Openpaths
data? Which one would you rather work with? Zoom into a part of the data
in Stamford and part of the data in Brooklyn. What's going on there?

### Foursquare data

The data from foursquare is on the complete opposite end of the spectrum
from Galileo. It only records locations when the user explicitly 'checks in'
to a particular location. For this feed, we can actually upload the data
directly into CartoDB as a kml file.

How does this data differ from the previous two? Is it better of worse?

Because we have additional information from the locations visited by foursquare,
we can display this as an info label on the map. Do this for the name
and link to the location in question. Publish as a new visualization.

### Census zip code

The final dataset we are going to look at comes from the US Census Bureau.
It contains demographic and spatial information for each zip code in the
United States. Because I am using the free tier account, I cannot load
the entire dataset in due to size restrictions. The script `getZipData.R`
subsets the raw file to include only zip codes between NYC and New Haven,
the only part we'll need for this tutorial anyway.

This time, we'll drag the entire zip file `lt_zips.zip` into CartoDB.
Notice that the data tab still has a field called ``the_geom_webmercator`,
but now the format seems to have changed from the other data sources.
Clicking on the map view, we see that this in this dataset each row
coorisponds to a region in space rather than an individual point. The
default map is fairly ugly, but we can again change this with the
wizard. Let's visualize the field `DP0010001`; the total population recorded
at the time of the 2010 census.

### Basic SQL (Structed Query Language)

With the exception of editing the CSS tab, we have not done anything
that required us to do more than select something from a menu.
We have gotten a lot with this approach, but in order to go further
we'll need to start writing our own queries using SQL (specifically, a
flavor called PostGRES).

We can start with a very basic query to filter the census data
(if you are familiar with SQL, note that CartoDB does not have a
final semicolon, a quirk that I often forget):
```{sql}
SELECT
  *
FROM
  lt_zips
WHERE
  DP0010001 > 10000
```
The formatting is not particularly important, and we could have written this
all on one line. Moving to the map view, we now see that only a subset of
the zip codes are now present.

With SQL, we can also construct derived columns. Most of the Census variables
are fairly boring on their own, but become interesting when used to derive
new measurements. For instance, say we want to derive the proportion of
respondants in a zip code who identify as white; we can do this by the
following:
```{sql}
SELECT
  *,
  (DP0080003 / (1.0 * DP0010001)) as w_perc
FROM
  lt_zips
WHERE
  DP0010001 > 0
```
Notice that we've limited the query to zip codes with non-zero populations.
I've also multiplied the value `DP0010001` by 1.0 in order to convert it to
a double (it was an integer). We can now use this new variable to generate
a visualization. Do you find the output at all surprising?

### Using SQL to join data

We've already seen how to use SQL to manipulate a table, but its true
power comes from being able to join two datasets together. Say we want
to 'enrich' the Openpaths data by matching each point to the zip code
it occured in. For that we use the following sql query (which can be
done within either table view):
```{sql}
SELECT
  openpaths_nolauren.cartodb_id,
  openpaths_nolauren.the_geom,
  openpaths_nolauren.the_geom_webmercator,
  lt_zips.zcta5ce10,
  (lt_zips.DP0080003 / (1.0 * lt_zips.DP0010001)) as w_perc
FROM
  openpaths_nolauren,
  lt_zips
WHERE
  ST_Intersects(openpaths_nolauren.the_geom, lt_zips.the_geom)
AND
  lt_zips.DP0010001 > 0
```
The fancy bit here is that we've used the function `ST_Intersects` to
identify which zip code each Openpaths data point belongs in. The resulting
data leads to some interesting additional visualizations.

We can also use SQL to generate tables useful
in their own right (that is, not to be used with a map).
```{sql}
SELECT
  lt_zips.cartodb_id,
  lt_zips.the_geom,
  lt_zips.the_geom_webmercator,
  lt_zips.zcta5ce10,
  count(*) as cnt
FROM
  openpaths_nolauren,
  lt_zips
WHERE
  ST_Intersects(openpaths_nolauren.the_geom, lt_zips.the_geom)
GROUP BY
  lt_zips.zcta5ce10
```
Sorting this table by count shows the zip codes with the most events.
Of course, we can also visualize this as a map to see a heatmap of
how often Lauren has a data point within a given zip code.

### Self-joins with SQL

A non-obvious use of the SQL join function is to do a self-join; that
is, to join a table to itself. Why would we want to do this? For one
example, perhaps we want to join each data point to the point which
occured right after it. Using the `cartodb_id`, this is actually quiet
easy. We will do a self-join on the Openpaths data, calculating the
distance travelled between successive points:
```{sql}
SELECT
  t1.cartodb_id,
  t1.the_geom,
  t1.the_geom_webmercator,
  ST_Distance(
      t1.the_geom::geography,
      t2.the_geom::geography
      ) / 1000 AS dist
FROM
  openpaths_nolauren t1,
  openpaths_nolauren t2
WHERE
  t1.cartodb_id = (t2.cartodb_id - 1)
```
Notice that we've had to name the tables `t1` and `t2` in the FROM
statment. Otherwise SQL would not know which of the two table copies
we are currently working with. If we visualize this data, using a
discrete coloring ramp, it seems that this can (almost) differentiate
modes of transportation used during the locates. Tweaking the CSS
would get even closer.

### Additional PostGRES-Specific SQL Functions (time permitting)

There are a range of other custom functions provided by the CartoDB
flavor of SQL. I'm not going to give a full description of these,
but wanted to point out two very helpful commands.

In the zip code based census file, most of the variables are raw
counts and therefore not particularly useful in their own right.
We already saw how to normalize by dividing by the total population,
but another way to standardize the data would be to divide by the
total area of the region. CartoDB, unsurprisingly, provides a
nice way of doing this:
```{sql}
SELECT
  openpaths_nolauren.cartodb_id,
  openpaths_nolauren.the_geom,
  openpaths_nolauren.the_geom_webmercator,
  lt_zips.zcta5ce10,
  lt_zips.DP0010001 / ST_Area() as pop_density
FROM
  openpaths_nolauren,
  lt_zips
WHERE
  ST_Intersects(openpaths_nolauren.the_geom, lt_zips.the_geom)
AND
  ST_Area() > 0
```
This, for instance, would have been a good way to standardize
the counts per zip code we did earlier.

Finally, we can also use the `ST_Distance` function to derive
the distance from a given point to ever other point in the
dataset. This is helpful, for instance, when the reference
point is of particular interest. Here we calculate the distance
of ever Openpaths data point to Lauren's home address (expressed
as latitude and longitude).
```{sql}
SELECT
  *,
  ST_Distance(
      the_geom::geography,
      CDB_LatLng(40.677629,-73.977959)::geography
      ) / 1000 AS dist
FROM
  openpaths_nolauren
```
Visualizing this, we can algorithmically labels points as being
either 'home' or 'away' by using CSS to differentiate based
on the variable `dist`.