import axios from 'axios';
import { Routes,Route } from 'react-router'  
import { useState,useEffect} from 'react';
import { HomePage } from '../pages/home/HomePage'
import { CheckoutPage } from '../pages/checkout/CheckoutPage'
import { OrdersPage } from '../pages/orders/OrdersPage'
import { TrackingPage} from '../pages/tracking/tracking'


import './App.css'


function App() {
  const [cart, setCart] = useState([]);

  const loadCart = async () => {
    const response = await axios.get('api/cart-items?expand=product');
    setCart(response.data);
  }

  useEffect(() => {
   
   loadCart();
  }, []);


  return (
    <Routes>
      <Route path="/" element={<HomePage cart={cart} loadCart={loadCart} />} />
      <Route path="/Checkout" element={<CheckoutPage cart={cart} />} />
      <Route path="/Orders" element={<OrdersPage cart={cart} />} />
      <Route path="/Tracking" element={<TrackingPage />} />
    </Routes>
  )
}

export default App
