public class RunningAverage
{
    int num_elements;
    float elements[];
    int next_element_index;
    
    fun void init(int new_num_elements)
    {
        new_num_elements => num_elements;
        float new_elements[num_elements] @=> elements;
        0 => next_element_index;
    }
    
    init(3);
    
    fun void add_element(float e)
    {
        e => elements[next_element_index];
        1 +=> next_element_index;
        num_elements %=> next_element_index;
    }
    
    fun float average()
    {
        0 => float sum;
        for (0 => int i; i < num_elements; i++)
        {
            elements[i] +=> sum;
        }
        return sum / num_elements;
    }
    
}