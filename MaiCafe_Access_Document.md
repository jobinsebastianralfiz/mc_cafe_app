# MaiCafe — System Access Document

**Prepared for:** MaiCafe Client  
**Date:** 19 April 2026  
**Application URL:** https://maicafeuk.com

---

## Table of Contents

1. [Admin Panel](#1-admin-panel)
2. [Kitchen Display](#2-kitchen-display)
3. [Counter / POS](#3-counter--pos)
4. [Order Status Display](#4-order-status-display)
5. [Customer-Facing Website](#5-customer-facing-website)
6. [Mobile App API](#6-mobile-app-api)
7. [Legal Pages](#7-legal-pages)

---

## 1. Admin Panel

The Admin Panel is the central control hub for managing the entire MaiCafe platform.

### Login

| Field    | Value                           |
|----------|---------------------------------|
| URL      | https://maicafeuk.com/login     |
| Email    | admin@maicafe.com               |
| Password | admin123                        |

> After login, you will be redirected to the Admin Dashboard at:  
> **https://maicafeuk.com/admin/dashboard**

### Admin Modules

| Module              | URL                                           | Description                                      |
|---------------------|-----------------------------------------------|--------------------------------------------------|
| Dashboard           | https://maicafeuk.com/admin/dashboard         | Overview: sales, orders, revenue stats           |
| Products            | https://maicafeuk.com/admin/products          | Add, edit, delete products and variants/addons   |
| Categories          | https://maicafeuk.com/admin/categories        | Manage product categories (food/cafe types)      |
| Orders              | https://maicafeuk.com/admin/orders            | View and manage all customer orders              |
| Customers           | https://maicafeuk.com/admin/customers         | View registered customer list and profiles       |
| Coupons             | https://maicafeuk.com/admin/coupons           | Create and manage discount coupons               |
| Banners             | https://maicafeuk.com/admin/banners           | Manage promotional banners shown in mobile app   |
| Addon Groups        | https://maicafeuk.com/admin/addons            | Manage product addon groups (extras, toppings)   |
| Stores              | https://maicafeuk.com/admin/stores            | View store/branch listings                       |
| Reports — Orders    | https://maicafeuk.com/admin/reports/orders    | Order history report with export (CSV)           |
| Reports — Inventory | https://maicafeuk.com/admin/reports/inventory | Inventory / product report with export (CSV)     |
| Settings            | https://maicafeuk.com/admin/settings          | App settings, email configuration, SMTP test     |
| Search              | https://maicafeuk.com/admin/search            | Global admin search across orders and products   |
| Kitchen View        | https://maicafeuk.com/admin/orders-kitchen    | Admin view of the live kitchen order display     |

---

## 2. Kitchen Display

A dedicated screen for kitchen staff to view and manage incoming orders in real time.

### Login

| Field    | Value                              |
|----------|------------------------------------|
| URL      | https://maicafeuk.com/kitchen/login |
| Email    | kitchen@maicafe.com                |
| Password | password123                        |

> After login, kitchen staff are redirected to:  
> **https://maicafeuk.com/kitchen**

### Kitchen Modules

| Module          | URL                                         | Description                                 |
|-----------------|---------------------------------------------|---------------------------------------------|
| Kitchen Dashboard | https://maicafeuk.com/kitchen             | Live view of orders in the queue            |
| Orders List     | https://maicafeuk.com/kitchen/orders        | Full list of kitchen orders                 |
| Update Order Status | *(via dashboard buttons)*              | Mark orders as preparing / ready            |

---

## 3. Counter / POS

A point-of-sale interface for counter staff to create walk-in sales, manage in-store orders, and confirm cash/card payments.

### Login

| Field    | Value                               |
|----------|-------------------------------------|
| URL      | https://maicafeuk.com/counter/login |
| Email    | counter@maicafe.com                 |
| Password | password123                         |

> After login, counter staff are redirected to:  
> **https://maicafeuk.com/counter**

### Counter Modules

| Module             | URL                                           | Description                                          |
|--------------------|-----------------------------------------------|------------------------------------------------------|
| Counter Dashboard  | https://maicafeuk.com/counter                 | Overview of orders awaiting payment and recent sales |
| New Sale (POS)     | https://maicafeuk.com/counter/sale            | Create a new walk-in order / POS sale                |
| Orders List        | https://maicafeuk.com/counter/orders          | View and manage all counter orders                   |
| Confirm Payment    | *(via order detail page)*                     | Confirm cash or card payment for awaiting orders     |

---

## 4. Order Status Display

A public-facing screen designed to be shown on a TV or display monitor at the pickup counter, showing customers which orders are ready.

| Field | Value                                         |
|-------|-----------------------------------------------|
| URL   | https://maicafeuk.com/order-status            |

> No login required. This page auto-refreshes and is safe to display on any public screen.

---

## 5. Customer-Facing Website

The public storefront accessible to all customers.

| Page          | URL                                      |
|---------------|------------------------------------------|
| Home          | https://maicafeuk.com                    |
| Menu          | https://maicafeuk.com/menu               |
| Stores        | https://maicafeuk.com/stores             |
| Cart          | https://maicafeuk.com/cart               |
| Login         | https://maicafeuk.com/login              |
| Register      | https://maicafeuk.com/register           |

---

## 6. Mobile App API

The REST API used by the MaiCafe mobile application (Flutter). All endpoints are prefixed with `/api`.

| Base URL | https://maicafeuk.com/api |
|----------|--------------------------|

### Key Endpoint Groups

| Group         | Base Path              | Authentication |
|---------------|------------------------|----------------|
| Auth          | /api/auth              | Public         |
| Products      | /api/products          | Bearer Token   |
| Categories    | /api/categories        | Bearer Token   |
| Banners       | /api/banners           | Bearer Token   |
| Cart          | /api/cart              | Bearer Token   |
| Orders        | /api/orders            | Bearer Token   |
| Wishlist      | /api/wishlist          | Bearer Token   |
| User Profile  | /api/user/profile      | Bearer Token   |
| Counter API   | /api/counter           | Bearer Token   |
| Shift4 Webhook | /api/webhooks/shift4  | Signature-verified |

---

## 7. Legal Pages

Publicly accessible pages for the mobile app's store listing compliance.

| Page                  | URL                                           |
|-----------------------|-----------------------------------------------|
| Privacy Policy        | https://maicafeuk.com/privacy-policy          |
| Terms & Conditions    | https://maicafeuk.com/terms-and-conditions    |

---

## Summary of Login Credentials

| Role           | Login URL                                    | Email                  | Password     |
|----------------|----------------------------------------------|------------------------|--------------|
| Admin          | https://maicafeuk.com/login                  | admin@maicafe.com      | admin123     |
| Kitchen Staff  | https://maicafeuk.com/kitchen/login          | kitchen@maicafe.com    | password123  |
| Counter Staff  | https://maicafeuk.com/counter/login          | counter@maicafe.com    | password123  |

---

> **Security Recommendation:** Please change all default passwords after your first login.  
> Admin password can be updated via **Admin Panel → Settings**.  
> Kitchen and counter passwords can be reset by the admin through the database or a future user management feature.
