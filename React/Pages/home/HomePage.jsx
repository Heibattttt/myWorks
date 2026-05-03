import axios from 'axios';
import { useEffect, useState } from 'react';
import { Header } from "../../src/components/Header";

import { ProductsGrid } from './ProductsGrid';




import './HomePage.css';


export function HomePage({cart, loadCart}) {
  const [products, setProducts] = useState([]);
  

  useEffect( () => {
    const getHomeData = async () => {
      const response =
        await axios.get('/api/products');
          
            // Update the products array with the fetched data
            setProducts(response.data);
          };
    
    getHomeData();
  }, []);

 

  return (
      <>
        <title>Ecommerce Project</title>

        <Header  cart={cart}/>

        <div className="home-page">
        <ProductsGrid products={products} loadCart={loadCart} />
      </div>
    </> 

);
} 

