## ACKNOWLEDGEMENT

This model is from Chapter Three of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, Ma. MIT Press.

## WHAT IS IT?

This project models the behavior of two types of turtles in a mythical pond. The red turtles and green turtles get along with one another. But each turtle wants to make sure that it lives near some of "its own." That is, each red turtle wants to live near at least some red turtles, and each green turtle wants to live near at least some green turtles. The simulation shows how these individual preferences ripple through the pond, leading to large-scale patterns.

This project was inspired by Thomas Schelling's writings about social systems (particularly with regards to housing segregation in cities).

This model is a simplified version of the Segregation model that is in the Social Science section of the NetLogo models library.

## HOW TO USE IT

Click the SETUP button to set up the turtles. There are equal numbers of red and green turtles. The turtles move around until there is at most one turtle on a patch.  Click GO to start the simulation. If turtles don't have enough same-color neighbors, they jump to a nearby patch.

The NUMBER slider controls the total number of turtles. (It takes effect the next time you click SETUP.)  The %-SIMILAR-WANTED slider controls the percentage of same-color turtles that each turtle wants among its neighbors. For example, if the slider is set at 30, each green turtle wants at least 30% of its neighbors to be green turtles.

The "PERCENT SIMILAR" monitor shows the average percentage of same-color neighbors for each turtle. It starts at about 0.5, since each turtle starts (on average) with an equal number of red and green turtles as neighbors. The "PERCENT UNHAPPY" monitor shows the percent of turtles that have fewer same-color neighbors than they want (and thus want to move).  Both monitors are also plotted.

## THINGS TO NOTICE

When you execute SETUP, the red and green turtles are randomly distributed throughout the pond. But many turtles are "unhappy" since they don't have enough same-color neighbors. The unhappy turtles jump to new locations in the vicinity. But in the new locations, they might tip the balance of the local population, prompting other turtles to leave. If a few red turtles move into an area, the local green turtles might leave. But when the green turtles move to a new area, they might prompt red turtles to leave that area.

Over time, the number of unhappy turtles decreases. But the pond becomes more segregated, with clusters of red turtles and clusters of green turtles.

In the case where each turtle wants at least 30% same-color neighbors, the turtles end up with (on average) 70% same-color neighbors. So relatively small individual preferences can lead to significant overall segregation.

## THINGS TO TRY

Try different values for %-SIMILAR-WANTED. How does the overall degree of segregation change?

If each turtle wants at least 40% same-color neighbors, what percentage (on average) do they end up with?

## NETLOGO FEATURES

In the UPDATE-GLOBALS procedure, note the use of SUM, COUNT, VALUES-FROM, and WITH to compute the percentages displayed in the monitors and plots.

## REFERENCES

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.  
See also a recent Atlantic article:   Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. http://www.theatlantic.com/issues/2002/04/rauch.htm

## HOW TO CITE

This model is part of the textbook, "Introduction to Agent-Based Modeling: Modeling 
 Natural, Social and Engineered Complex Systems using NetLogo."
 
If you mention this model or the NetLogo software in a publication, we ask that you include the cites.

For the model itself:

* Wilensky, U. & Rand, W. (2006).  NetLogo Segregation Simple model.  http://ccl.northwestern.edu/netlogo/models/IABM Textbook/SegregationSimple.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U  & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling 
 Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, Ma. MIT Press.